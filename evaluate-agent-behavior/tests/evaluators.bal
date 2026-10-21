import ballerina/ai;
import ballerina/constraint;

# Tools that change state. The agent must call them only when the expected trace does.
final readonly & string[] sideEffectTools = ["openSupportTicket"];

final string:RegExp emailAddress = re `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`;

# Returns the final answer of an agent run.
#
# + trace - The trace of the run
# + return - The answer, or an error if the run failed or returned an empty answer
isolated function answerOf(ai:Trace trace) returns string|error {
    ai:ChatAssistantMessage|ai:Error output = trace.output;
    if output is ai:Error {
        return error("agent run failed", output);
    }
    string? content = output.content;
    if content is () || content.trim().length() == 0 {
        return error("agent returned an empty answer");
    }
    return content;
}

# Checks the tool calls of a run against the expected tool calls.
# Every expected call must be made with the expected arguments. Arguments that are not in the
# expected call are ignored, so leave out free-text arguments. Additional calls to read-only tools
# are allowed, but a call to a side-effecting tool that is not expected is a violation.
#
# + expected - The tool calls in the expected trace
# + actual - The tool calls made in the run
# + return - A description of each violation, or an empty array if there are none
isolated function checkToolCalls(ai:FunctionCall[] expected, ai:FunctionCall[] actual) returns string[] {
    string[] violations = [];
    foreach ai:FunctionCall call in expected {
        boolean found = false;
        foreach ai:FunctionCall actualCall in actual {
            if actualCall.name == call.name && argumentsMatch(call.arguments, actualCall.arguments) {
                found = true;
                break;
            }
        }
        if !found {
            violations.push(string `missing tool call: ${call.name}(${(call.arguments ?: {}).toJsonString()})`);
        }
    }
    string[] expectedNames = from ai:FunctionCall call in expected
        select call.name;
    foreach ai:FunctionCall call in actual {
        if sideEffectTools.indexOf(call.name) != () && expectedNames.indexOf(call.name) == () {
            violations.push(string `unexpected call to side-effecting tool: ${call.name}`);
        }
    }
    return violations;
}

isolated function argumentsMatch(map<json>? expected, map<json>? actual) returns boolean {
    map<json> actualArgs = actual ?: {};
    foreach [string, json] [name, value] in (expected ?: {}).entries() {
        if actualArgs[name] != value {
            return false;
        }
    }
    return true;
}

# Checks that an answer does not contain contact details.
#
# + answer - The final answer of the agent
# + return - A description of each violation, or an empty array if there are none
isolated function checkNoContactDetails(string answer) returns string[] {
    if emailAddress.find(answer) is () {
        return [];
    }
    return ["answer contains an email address"];
}

# The verdict of the judge model.
type JudgeVerdict record {|
    # Score from 1 (wrong or unhelpful) to 5 (the same facts and action as the reference answer)
    @constraint:Int {minValue: 1, maxValue: 5}
    int score;
    # One sentence that explains the score
    string reason;
|};

# The minimum judge score for an answer to pass.
const MIN_JUDGE_SCORE = 4;

# Asks a model to compare an answer with a reference answer.
#
# + judge - The model provider used as the judge
# + question - The customer's message
# + reference - The reference answer from the evaluation dataset
# + actual - The answer produced by the agent
# + return - The verdict, or an error if the judge fails or returns an invalid verdict
isolated function judgeAnswer(ai:ModelProvider judge, string question, string reference, string actual)
        returns JudgeVerdict|error {
    JudgeVerdict verdict = check judge->generate(`You are evaluating a customer support agent of a broadband provider.
        Compare the actual answer with the reference answer to the customer's message.
        Give a score of 5 if the actual answer gives the same facts and reports the same action as the
        reference answer, even if it is worded differently. Give a score of 1 if it is wrong, misleading,
        or does not answer the message. Identifiers generated at run time, such as ticket IDs, can differ.
        Do not reward length or politeness.

        Customer message: ${question}
        Reference answer: ${reference}
        Actual answer: ${actual}`);
    return constraint:validate(verdict);
}
