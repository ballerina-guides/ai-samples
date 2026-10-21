import ballerina/log;
import ballerina/mcp;

configurable int port = 9090;

listener mcp:StreamableHttpListener mcpListener = new (port);

@mcp:StreamableHttpServiceConfig {
    info: {name: "customer-care-tools", version: "1.0.0"},
    sessionMode: mcp:STATELESS
}
service mcp:StreamableHttpService /mcp on mcpListener {

    # Search the product catalog by product name and return the price and the number of units in stock.
    # Use this to answer questions about product availability or price.
    #
    # + query - Part of the product name to search for (at least 2 characters)
    # + return - Up to 5 matching products, or an explanation if the query is invalid
    remote function searchProducts(string query) returns Product[]|ToolMessage {
        log:printInfo("Tool called", tool = "searchProducts", query = query);
        return findProducts(query);
    }

    # Get the current status of an order. Use this when a customer asks where an order is.
    #
    # + orderId - Order ID in the format ORD-NNNN (for example ORD-1001)
    # + return - The order status, or an explanation if the order is not found
    remote function getOrderStatus(string orderId) returns OrderStatus|ToolMessage {
        log:printInfo("Tool called", tool = "getOrderStatus", orderId = orderId);
        return findOrderStatus(orderId);
    }

    # Submit a return request for a delivered order. Only call this after the customer
    # has confirmed that they want to return the order and has given a reason.
    #
    # + orderId - Order ID in the format ORD-NNNN (for example ORD-1001)
    # + reason - The reason for the return in the customer's words
    # + return - The created return request, or an explanation if the return is not allowed
    remote function submitReturnRequest(string orderId, string reason) returns ReturnRequest|ToolMessage {
        log:printInfo("Tool called", tool = "submitReturnRequest", orderId = orderId);
        return createReturnRequest(orderId, reason);
    }

    # Issue a full refund for an order. For back-office staff only.
    #
    # + orderId - Order ID in the format ORD-NNNN (for example ORD-1001)
    # + return - The issued refund, or an explanation if the order is not found
    remote function issueRefund(string orderId) returns Refund|ToolMessage {
        log:printInfo("Tool called", tool = "issueRefund", orderId = orderId);
        return createRefund(orderId);
    }
}
