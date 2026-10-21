import ballerina/ai;
import ballerina/http;
import ballerina/log;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;
configurable string mcpServerUrl = "http://localhost:9090/mcp";
configurable decimal mcpTimeout = 30;
configurable int port = 8080;

const MAX_MESSAGE_LENGTH = 2000;

// The MCP server tools that this agent may use. `issueRefund` is a back-office
// tool, so it is not given to the customer-facing agent.
final string[] & readonly permittedTools = ["searchProducts", "getOrderStatus", "submitReturnRequest"];

final ai:ModelProvider model = check new openai:ModelProvider(openAiApiKey, openai:GPT_4O);

// Created on first use, so that the service starts even if the MCP server is not up yet.
isolated ai:Agent? customerCareAgent = ();

type ChatRequest record {|
    string sessionId;
    string message;
|};

type ChatResponse record {|
    string reply;
|};

service /support on new http:Listener(port) {
    resource function post chat(ChatRequest request)
            returns ChatResponse|http:BadRequest|http:BadGateway|http:ServiceUnavailable {
        string? invalid = validateChatRequest(request);
        if invalid is string {
            return <http:BadRequest>{body: invalid};
        }

        ai:Agent|ai:Error agent = getAgent();
        if agent is ai:Error {
            log:printError("Cannot connect to the MCP server", agent, serverUrl = mcpServerUrl);
            return <http:ServiceUnavailable>{body: "Customer care is temporarily unavailable. Try again later."};
        }

        string|ai:Error reply = agent.run(request.message, request.sessionId);
        if reply is ai:Error {
            log:printError("Agent run failed", reply, sessionId = request.sessionId);
            return toErrorResponse(reply);
        }
        return {reply};
    }
}

# Returns the agent, creating it and connecting to the MCP server on first use.
# If the MCP server cannot be reached, the error is returned and the next call tries again.
#
# + return - The agent, or an error if the MCP server cannot be reached
isolated function getAgent() returns ai:Agent|ai:Error {
    lock {
        ai:Agent? existing = customerCareAgent;
        if existing is ai:Agent {
            return existing;
        }
        ai:McpToolKit toolKit = check createMcpToolKit(mcpServerUrl);
        ai:Agent agent = check new (
            systemPrompt = {
                role: "Customer Care Agent",
                instructions: string `You help customers of an online store with product availability,
                    order status, and returns. Always use the tools to look up products and orders
                    instead of guessing. If a tool returns an outcome such as NOT_FOUND or NOT_ALLOWED,
                    explain it to the customer in plain words. Before you submit a return request,
                    confirm the order ID and the reason with the customer. Include order IDs and return
                    IDs in your replies. Keep replies short.`
            },
            model = model,
            tools = [toolKit],
            maxIter = 10
        );
        customerCareAgent = agent;
        return agent;
    }
}

# Connects to the MCP server and loads only the permitted tools.
#
# + serverUrl - The URL of the MCP server endpoint
# + return - The toolkit, or an error if the server cannot be reached or initialized
isolated function createMcpToolKit(string serverUrl) returns ai:McpToolKit|ai:Error {
    return new (serverUrl, permittedTools, {name: "customer-care-agent", version: "1.0.0"}, timeout = mcpTimeout);
}

# Validates a chat request before it is sent to the agent.
#
# + request - The chat request
# + return - An error message if the request is invalid, or `()` otherwise
isolated function validateChatRequest(ChatRequest request) returns string? {
    if !re `[A-Za-z0-9_-]{1,64}`.isFullMatch(request.sessionId) {
        return "sessionId must have 1 to 64 letters, digits, '-', or '_'";
    }
    string message = request.message.trim();
    if message.length() == 0 || message.length() > MAX_MESSAGE_LENGTH {
        return string `message must have between 1 and ${MAX_MESSAGE_LENGTH} characters`;
    }
    return ();
}

# Maps an agent error to an HTTP response without exposing internal details.
#
# + err - The error returned by the agent
# + return - `503 Service Unavailable` if the model cannot be reached, `502 Bad Gateway` otherwise
isolated function toErrorResponse(ai:Error err) returns http:BadGateway|http:ServiceUnavailable {
    if isModelUnreachable(err) {
        return <http:ServiceUnavailable>{body: "Customer care is temporarily unavailable. Try again later."};
    }
    if err is ai:MaxIterationExceededError {
        return <http:BadGateway>{body: "The request could not be completed. Try a more specific question."};
    }
    return <http:BadGateway>{body: "The request could not be completed."};
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
