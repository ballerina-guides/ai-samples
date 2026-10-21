import ballerina/ai;
import ballerina/http;
import ballerina/jwt;
import ballerina/log;
import ballerina/observe;

configurable int servicePort = 8080;
configurable string tokenIssuer = ?;
configurable string tokenAudience = ?;
configurable string issuerCertFile = ?;

const REQUIRED_SCOPE = "claims:assist";
const MAX_MESSAGE_LENGTH = 2000;

// Validates the bearer token sent by the client application.
final http:ListenerJwtAuthHandler jwtHandler = new ({
    issuer: tokenIssuer,
    audience: tokenAudience,
    signatureConfig: {certFile: issuerCertFile},
    scopeKey: "scope"
});

service /assistant on new http:Listener(servicePort) {
    resource function post chat(http:Headers headers, ai:ChatReqMessage request)
            returns ai:ChatRespMessage|http:BadRequest|http:Unauthorized|http:Forbidden|
                http:ServiceUnavailable|http:InternalServerError {
        // 1. Authenticate the caller and check the scope before doing any work.
        string|http:Unauthorized|http:Forbidden policyholderId = authenticate(headers);
        if policyholderId !is string {
            return policyholderId;
        }

        // 2. Validate the request and remove personal data from the message.
        string? validationError = validateChatRequest(request);
        if validationError is string {
            return <http:BadRequest>{body: validationError};
        }
        [string, int] [message, redactedValues] = redactPii(request.message);

        // 3. Log and trace metadata about the request, not its content.
        ChatAuditEntry audit = {
            sessionId: request.sessionId,
            policyholderId,
            messageLength: request.message.length(),
            redactedValues
        };
        log:printInfo("Chat request received", audit = audit);
        if observe:isTracingEnabled() {
            error? tagged = observe:addTagToSpan("claims.redacted_values", redactedValues.toString());
            if tagged is error {
                log:printDebug("Could not add the tag to the span", tagged);
            }
        }

        // 4. Run the agent. Tools read the policyholder from the context.
        ai:Context ctx = new;
        ctx.set(POLICYHOLDER_ID, policyholderId);
        // Scope the conversation memory to the user, so that one user cannot continue another user's session.
        string sessionId = string `${policyholderId}:${request.sessionId}`;
        string|ai:Error answer = claimsAgent.run(message, sessionId, ctx);

        // 5. Map the outcome to an HTTP response.
        if ctx.hasKey(TOOL_ACCESS_DENIED) {
            return <http:InternalServerError>{body: "The assistant could not complete the request"};
        }
        if ctx.hasKey(BACKEND_UNAVAILABLE) {
            return <http:ServiceUnavailable>{body: "The claims system is temporarily unavailable"};
        }
        if answer is ai:Error && isModelUnavailable(answer) {
            log:printError("Model provider is unreachable", answer);
            return <http:ServiceUnavailable>{body: "The assistant is temporarily unavailable"};
        }
        if answer is ai:Error {
            log:printError("Agent run failed", answer, sessionId = request.sessionId);
            return <http:InternalServerError>{body: "The assistant could not complete the request"};
        }
        return {message: answer};
    }
}

# Validates the bearer token and checks that it grants the scope required to use the assistant.
#
# + headers - The request headers
# + return - The ID of the authenticated policyholder (the `sub` claim), or the response to send
isolated function authenticate(http:Headers headers) returns string|http:Unauthorized|http:Forbidden {
    jwt:Payload|http:Unauthorized result = jwtHandler.authenticate(headers);
    if result is http:Unauthorized {
        return result;
    }
    jwt:Payload payload = <jwt:Payload>result;
    http:Forbidden? forbidden = jwtHandler.authorize(payload, REQUIRED_SCOPE);
    if forbidden is http:Forbidden {
        return forbidden;
    }
    string? subject = payload.sub;
    if subject is () {
        return <http:Unauthorized>{body: "The token does not identify a user"};
    }
    return subject;
}

# Checks whether an agent run failed because the model provider could not be reached.
# The agent reports a failed model call as an `ai:Error` that lists the failed steps.
#
# + err - The error returned by the agent
# + return - `true` if the model provider could not be reached
isolated function isModelUnavailable(ai:Error err) returns boolean {
    if err is ai:LlmConnectionError {
        return true;
    }
    var steps = err.detail()["steps"];
    if steps is (any|error)[] {
        foreach var step in steps {
            if step is ai:LlmConnectionError {
                return true;
            }
        }
    }
    return false;
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
