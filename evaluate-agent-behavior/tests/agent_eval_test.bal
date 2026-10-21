import ballerina/ai;
import ballerina/test;
import ballerinax/ai.openai;

const EVALSET_PATH = "tests/resources/evalsets/broadband_support.evalset.json";

final ai:ModelProvider judgeModel = check new openai:ModelProvider(openAiApiKey, openai:GPT_4O, temperature = 0.0d);

isolated function supportThreads() returns map<[readonly & ai:ConversationThread]>|error =>
    ai:loadConversationThreads(EVALSET_PATH);

@test:Config {
    groups: ["live-eval"],
    dataProvider: supportThreads,
    runs: 3,
    minPassRate: 0.8
}
isolated function evaluateSupportAgent(ai:ConversationThread thread) returns error? {
    // A new agent per thread gives each conversation its own memory.
    ai:Agent agent = check createSupportAgent(model);
    foreach ai:Trace expected in thread.traces {
        string question = ai:getUserQuery(expected);
        ai:Trace actual = check agent.run(question, thread.id);
        string answer = check answerOf(actual);

        string[] violations = [
            ...checkToolCalls(expected.toolCalls ?: [], actual.toolCalls ?: []),
            ...checkNoContactDetails(answer)
        ];
        test:assertTrue(violations.length() == 0,
                string `[${expected.id}] rule violations: ${violations.toString()}; answer: ${answer}`);

        JudgeVerdict verdict = check judgeAnswer(judgeModel, question, check answerOf(expected), answer);
        test:assertTrue(verdict.score >= MIN_JUDGE_SCORE,
                string `[${expected.id}] judge score ${verdict.score}: ${verdict.reason}; answer: ${answer}`);
    }
}
