import ballerina/mcp;
import ballerina/test;

@test:Config
function testServerAdvertisesTools() returns error? {
    mcp:StreamableHttpClient mcpClient = check new (string `http://localhost:${port}/mcp`);
    check mcpClient->initialize({name: "test-client", version: "1.0.0"});

    mcp:ListToolsResult tools = check mcpClient->listTools();
    string[] names = from mcp:ToolDefinition tool in tools.tools
        order by tool.name
        select tool.name;
    test:assertEquals(names, ["getOrderStatus", "issueRefund", "searchProducts", "submitReturnRequest"]);

    mcp:CallToolResult result = check mcpClient->callTool({
        name: "getOrderStatus",
        arguments: {"orderId": "ORD-1003"}
    });
    mcp:ContentBlock content = result.content[0];
    test:assertTrue(content is mcp:TextContent && content.text.includes("PROCESSING"));
    check mcpClient->close();
}
