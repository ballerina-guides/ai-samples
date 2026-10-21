import ballerina/ai;
import ballerina/http;
import ballerina/log;

# A message from a customer.
type ChatRequest record {|
    # Identifies the conversation
    string sessionId;
    # The customer's message
    string message;
|};

# The agent's reply.
type ChatResponse record {|
    # The agent's answer
    string reply;
|};

configurable int port = 8080;

service /support on new http:Listener(port) {
    private final ai:Agent agent;

    function init() returns error? {
        self.agent = check createSupportAgent(model);
    }

    resource function post chat(ChatRequest request)
            returns ChatResponse|http:BadRequest|http:BadGateway {
        if request.message.trim().length() == 0 {
            return <http:BadRequest>{body: "message must not be empty"};
        }
        string|ai:Error reply = self.agent.run(request.message, request.sessionId);
        if reply is ai:Error {
            log:printError("Agent run failed", reply, sessionId = request.sessionId);
            return <http:BadGateway>{body: "The support agent could not complete the request"};
        }
        return {reply};
    }
}
