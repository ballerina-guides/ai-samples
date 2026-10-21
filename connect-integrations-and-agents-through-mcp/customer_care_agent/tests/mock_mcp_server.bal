import ballerina/mcp;

// A stand-in for the customer care MCP server, with the same tool names.
service mcp:StreamableHttpService /mcp on new mcp:StreamableHttpListener(9292) {
    remote function searchProducts(string query) returns json => [];
    remote function getOrderStatus(string orderId) returns json => {};
    remote function submitReturnRequest(string orderId, string reason) returns json => {};
    remote function issueRefund(string orderId) returns json => {};
}
