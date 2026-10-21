import ballerina/test;

@test:Config
function testSearchFindsProductsByName() {
    Product[]|ToolMessage result = findProducts("Headphones");
    if result is ToolMessage {
        test:assertFail(result.message);
    }
    test:assertEquals(result.map(product => product.sku), ["HP-100", "HP-200"]);
}

@test:Config
function testShortSearchTextIsRejected() {
    Product[]|ToolMessage result = findProducts(" h ");
    test:assertTrue(result is ToolMessage && result.outcome == "INVALID_INPUT");
}

@test:Config
function testOrderStatusLeavesOutCustomerEmail() {
    OrderStatus|ToolMessage result = findOrderStatus("ORD-1002");
    if result is ToolMessage {
        test:assertFail(result.message);
    }
    test:assertEquals(result.state, "SHIPPED");
    test:assertFalse(result.toJson().toJsonString().includes("@example.com"));
}

@test:Config
function testUnknownAndMalformedOrderIds() {
    OrderStatus|ToolMessage unknown = findOrderStatus("ORD-9999");
    test:assertTrue(unknown is ToolMessage && unknown.outcome == "NOT_FOUND");
    OrderStatus|ToolMessage malformed = findOrderStatus("1001");
    test:assertTrue(malformed is ToolMessage && malformed.outcome == "INVALID_INPUT");
}

@test:Config
function testReturnRequestRules() {
    ReturnRequest|ToolMessage notDelivered = createReturnRequest("ORD-1002", "Changed my mind");
    test:assertTrue(notDelivered is ToolMessage && notDelivered.outcome == "NOT_ALLOWED");

    ReturnRequest|ToolMessage noReason = createReturnRequest("ORD-1001", "  ");
    test:assertTrue(noReason is ToolMessage && noReason.outcome == "INVALID_INPUT");

    ReturnRequest|ToolMessage created = createReturnRequest("ORD-1001", "Arrived damaged");
    if created is ToolMessage {
        test:assertFail(created.message);
    }
    test:assertEquals(created.orderId, "ORD-1001");

    ReturnRequest|ToolMessage duplicate = createReturnRequest("ORD-1001", "Arrived damaged");
    test:assertTrue(duplicate is ToolMessage && duplicate.outcome == "NOT_ALLOWED");
}

@test:Config
function testRefundAmountIsOrderTotal() {
    Refund|ToolMessage refund = createRefund("ORD-1002");
    test:assertEquals(refund, {orderId: "ORD-1002", amount: 59.49d});
}
