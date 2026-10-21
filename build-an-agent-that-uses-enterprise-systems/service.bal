import ballerina/ai;
import ballerina/http;
import ballerina/log;

configurable int servicePort = 8080;

const MAX_MESSAGE_LENGTH = 2000;

service /support on new http:Listener(servicePort) {
    resource function post chat(ai:ChatReqMessage request)
            returns ai:ChatRespMessage|http:BadRequest|http:ServiceUnavailable|http:InternalServerError {
        string? validationError = validateChatRequest(request);
        if validationError is string {
            return <http:BadRequest>{body: validationError};
        }

        // A new context per request. Tools use it to report backend outages.
        ai:Context ctx = new;
        string|ai:Error answer = orderSupportAgent.run(request.message, request.sessionId, ctx);

        if ctx.hasKey(BACKEND_UNAVAILABLE) {
            return <http:ServiceUnavailable>{body: "The order system is temporarily unavailable"};
        }
        if answer is ai:Error && isModelUnreachable(answer) {
            log:printError("Model provider is unreachable", answer);
            return <http:ServiceUnavailable>{body: "The assistant is temporarily unavailable"};
        }
        if answer is ai:MaxIterationExceededError {
            log:printWarn("Agent exceeded the iteration limit", sessionId = request.sessionId);
            return <http:InternalServerError>{body: "The assistant could not complete the request"};
        }
        if answer is ai:Error {
            log:printError("Agent run failed", answer, sessionId = request.sessionId);
            return <http:InternalServerError>{body: "The assistant could not complete the request"};
        }
        return {message: answer};
    }
}

# Validates a chat request before it is passed to the agent.
#
# + request - The chat request
# + return - A description of the problem, or `()` if the request is valid
isolated function validateChatRequest(ai:ChatReqMessage request) returns string? {
    if request.sessionId.trim().length() == 0 {
        return "sessionId must not be empty";
    }
    string message = request.message.trim();
    if message.length() == 0 {
        return "message must not be empty";
    }
    if message.length() > MAX_MESSAGE_LENGTH {
        return string `message must not exceed ${MAX_MESSAGE_LENGTH} characters`;
    }
    return;
}

# Checks whether an agent error was caused by a failure to connect to the model.
# The agent reports a failed run as an `ai:Error` whose `steps` detail holds the error of each step.
#
# + err - The error returned by the agent
# + return - `true` if the model could not be reached
isolated function isModelUnreachable(ai:Error err) returns boolean {
    if err is ai:LlmConnectionError {
        return true;
    }
    anydata|readonly steps = err.detail()["steps"];
    if steps is readonly & (any|error)[] {
        foreach any|error step in steps {
            if step is ai:LlmConnectionError {
                return true;
            }
        }
    }
    return false;
}
