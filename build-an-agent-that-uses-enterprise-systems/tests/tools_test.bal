import ballerina/ai;
import ballerina/http;
import ballerina/test;

@test:Config
function testGetOrderReturnsOrder() returns error? {
    Order 'order = check getOrder(new ai:Context(), "ORD-1001");
    test:assertEquals('order.status, SHIPPED);
    test:assertEquals('order.trackingNumber, "TRK-55501");
}

@test:Config
function testUnknownOrderIsReturnedToModel() {
    ai:Context ctx = new;
    Order|error result = getOrder(ctx, "ORD-9999");
    test:assertTrue(result is error);
    test:assertEquals((<error>result).message(), "Order ORD-9999 not found");
    // A missing order is a business error, not an outage.
    test:assertFalse(ctx.hasKey(BACKEND_UNAVAILABLE));
}

@test:Config
function testInvalidOrderIdIsRejected() {
    Order|error result = getOrder(new ai:Context(), "1001");
    test:assertTrue(result is error);
    test:assertEquals((<error>result).message(),
            "'1001' is not a valid order ID. Order IDs have the format ORD-1234.");
}

@test:Config
function testShippedOrderCannotBeCancelled() {
    Order|error result = cancelOrder(new ai:Context(), "ORD-1001", "Changed my mind");
    test:assertTrue(result is error);
    test:assertEquals((<error>result).message(), "Order ORD-1001 is SHIPPED and cannot be cancelled");
}

@test:Config
function testEmptyReasonIsRejected() {
    Order|error result = cancelOrder(new ai:Context(), "ORD-1002", "   ");
    test:assertTrue(result is error);
}

@test:Config {
    dependsOn: [testEmptyReasonIsRejected]
}
function testPendingOrderIsCancelled() returns error? {
    Order 'order = check cancelOrder(new ai:Context(), "ORD-1002", "Ordered by mistake");
    test:assertEquals('order.status, CANCELLED);
}

@test:Config
function testConnectionFailureMarksBackendUnavailable() {
    ai:Context ctx = new;
    error result = toToolError(ctx, error http:ClientConnectorError("Connection refused"));
    test:assertEquals(result.message(), "The order system is unavailable. Do not retry.");
    test:assertTrue(ctx.hasKey(BACKEND_UNAVAILABLE));
}

@test:Config
function testShipmentToolIsRegistered() {
    ai:ToolConfig[] tools = shipmentToolKit.getTools();
    test:assertEquals(tools.length(), 1);
    test:assertEquals(tools[0].name, "getShipment");
}

@test:Config
function testChatRequestValidation() {
    test:assertEquals(validateChatRequest({sessionId: "", message: "Hi"}), "sessionId must not be empty");
    test:assertEquals(validateChatRequest({sessionId: "s1", message: " "}), "message must not be empty");
    test:assertEquals(validateChatRequest({sessionId: "s1", message: "Where is ORD-1001?"}), ());
}

@test:Config
function testModelConnectionFailureIsDetected() {
    test:assertTrue(isModelUnreachable(error ai:LlmConnectionError("timeout")));
    ai:Error failedRun = error ai:Error("Unable to obtain valid answer from the agent",
        steps = [error ai:LlmConnectionError("Error while connecting to the model")]);
    test:assertTrue(isModelUnreachable(failedRun));
    test:assertFalse(isModelUnreachable(error ai:Error("Unable to obtain valid answer from the agent", steps = [])));
    test:assertFalse(isModelUnreachable(error ai:MaxIterationExceededError("limit", steps = [])));
}
