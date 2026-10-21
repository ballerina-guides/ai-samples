import ballerina/ai;
import ballerina/http;
import ballerina/test;

@test:Config
function testOnlyPermittedToolsAreLoaded() returns error? {
    ai:McpToolKit toolKit = check createMcpToolKit("http://localhost:9292/mcp");
    string[] names = from ai:ToolConfig tool in toolKit.getTools()
        order by tool.name
        select tool.name;
    test:assertEquals(names, ["getOrderStatus", "searchProducts", "submitReturnRequest"]);
}

@test:Config
function testUnreachableMcpServerReturnsError() {
    ai:McpToolKit|ai:Error toolKit = createMcpToolKit("http://localhost:9393/mcp");
    test:assertTrue(toolKit is ai:Error);
}

@test:Config
function testChatReturns503WhenMcpServerIsDown() returns error? {
    http:Client supportClient = check new (string `http://localhost:${port}/support`);
    http:Response response = check supportClient->post("/chat", {sessionId: "s-1", message: "Where is ORD-1002?"});
    test:assertEquals(response.statusCode, 503);
}

@test:Config
function testInvalidChatRequestsAreRejected() {
    test:assertTrue(validateChatRequest({sessionId: "s-1", message: "Hi"}) is ());
    test:assertTrue(validateChatRequest({sessionId: "", message: "Hi"}) is string);
    test:assertTrue(validateChatRequest({sessionId: "s 1", message: "Hi"}) is string);
    test:assertTrue(validateChatRequest({sessionId: "s-1", message: "   "}) is string);
}

@test:Config
function testAgentErrorsMapToHttpStatus() {
    test:assertTrue(toErrorResponse(error ai:LlmConnectionError("timeout")) is http:ServiceUnavailable);
    ai:Error failedRun = error ai:Error("Unable to obtain valid answer from the agent",
        steps = [error ai:LlmConnectionError("Error while connecting to the model")]);
    test:assertTrue(toErrorResponse(failedRun) is http:ServiceUnavailable);
    test:assertTrue(toErrorResponse(error ai:MaxIterationExceededError("limit", steps = [])) is http:BadGateway);
    test:assertTrue(toErrorResponse(error ai:Error("other")) is http:BadGateway);
}
