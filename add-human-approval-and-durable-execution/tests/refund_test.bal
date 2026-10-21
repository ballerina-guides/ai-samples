import ballerina/test;

final Order delivered = {orderId: "ORD-1", customerId: "CUS-1", status: "DELIVERED", total: 100d, refunded: 30d};

@test:Config
function testRefundWithinLimitIsAllowed() {
    test:assertEquals(checkRefundPolicy(delivered, 70d), ());
}

@test:Config
function testRefundAboveRefundableAmountIsRejected() {
    test:assertTrue(checkRefundPolicy(delivered, 70.01d) is string);
}

@test:Config
function testNonPositiveAmountIsRejected() {
    test:assertTrue(checkRefundPolicy(delivered, 0d) is string);
}

@test:Config
function testUndeliveredOrderIsRejected() {
    Order shipped = {orderId: "ORD-2", customerId: "CUS-1", status: "SHIPPED", total: 100d, refunded: 0d};
    test:assertTrue(checkRefundPolicy(shipped, 10d) is string);
}

@test:Config
function testIdempotencyKeyDependsOnlyOnOrder() {
    test:assertEquals(refundKey("ORD-1001"), refundKey("ORD-1001"));
    test:assertNotEquals(refundKey("ORD-1001"), refundKey("ORD-1002"));
}

@test:Config
function testRepeatedRefundDoesNotPayTwice() returns error? {
    GatewayRequest first = check submitRefund("refund-ORD-9", "ORD-9", 10d, "test");
    GatewayRequest second = check submitRefund("refund-ORD-9", "ORD-9", 10d, "test");
    test:assertFalse(first.duplicate);
    test:assertTrue(second.duplicate);
    test:assertEquals(second.refundId, first.refundId);
}
