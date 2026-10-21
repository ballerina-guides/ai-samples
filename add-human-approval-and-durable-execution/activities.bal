import ballerina/log;
import ballerina/workflow;

# Maximum share of an order total that can be refunded through this flow.
configurable decimal maxRefundRatio = 1.0;
# Number of times the simulated payment gateway fails before it accepts a refund.
# Set it to a positive value to try out the failure review.
configurable int gatewayFailuresBeforeSuccess = 0;

// Simulated order system.
final readonly & map<Order> orders = {
    "ORD-1001": {orderId: "ORD-1001", customerId: "CUS-42", status: "DELIVERED", total: 120.00d, refunded: 0d},
    "ORD-1002": {orderId: "ORD-1002", customerId: "CUS-42", status: "SHIPPED", total: 64.50d, refunded: 0d},
    "ORD-1003": {orderId: "ORD-1003", customerId: "CUS-77", status: "DELIVERED", total: 300.00d, refunded: 300.00d}
};

// Simulated payment gateway state, keyed by idempotency key.
type GatewayRequest record {|
    # Number of requests received with the key
    int attempts;
    # The refund ID, once the refund is accepted
    string? refundId;
    # Whether the last request repeated an accepted one
    boolean duplicate = false;
|};

isolated map<GatewayRequest> gatewayRequests = {};

# Returns an order, including its status, total, and the amount already refunded.
#
# + orderId - The order ID, in the form `ORD-<number>`
# + return - The order, or an error if no such order exists
@workflow:Activity
isolated function getOrder(string orderId) returns Order|error {
    Order? 'order = orders[orderId];
    if 'order is () {
        return error(string `Order ${orderId} not found`);
    }
    return 'order;
}

# Refunds an amount to the customer's original payment method. Check the order with
# `getOrder` first. At most one refund is issued per order.
#
# + orderId - The order to refund
# + amount - The amount to refund, in the order currency
# + reason - A short reason for the refund, recorded with the payment
# + return - The refund result, or an error if the payment gateway call failed
@workflow:Activity
isolated function issueRefund(string orderId, decimal amount, string reason) returns RefundResult|error {
    Order? 'order = orders[orderId];
    if 'order is () {
        return {status: "REJECTED", orderId, amount, message: string `Order ${orderId} not found`};
    }
    string? violation = checkRefundPolicy('order, amount);
    if violation is string {
        // A policy violation is a business outcome, not a failure: return it as a value
        // so that it is not retried.
        return {status: "REJECTED", orderId, amount, message: violation};
    }
    GatewayRequest gatewayResult = check submitRefund(refundKey(orderId), orderId, amount, reason);
    string refundId = gatewayResult.refundId ?: "";
    if gatewayResult.duplicate {
        return {status: "ISSUED", orderId, amount, refundId,
            message: "A refund was already issued for this order; no new payment was made"};
    }
    return {status: "ISSUED", orderId, amount, refundId, message: "Refund issued"};
}

# Sends a message to a customer.
#
# + customerId - The customer to notify
# + message - The message text
# + return - An error if the message could not be sent
@workflow:Activity
isolated function notifyCustomer(string customerId, string message) returns error? {
    log:printInfo("Customer notified", customerId = customerId, text = message);
}

# Checks a proposed refund against the refund policy.
#
# + 'order - The order to refund
# + amount - The proposed refund amount
# + return - A description of the violated rule, or `()` if the refund is allowed
isolated function checkRefundPolicy(Order 'order, decimal amount) returns string? {
    if 'order.status != "DELIVERED" {
        return string `Order ${'order.orderId} is ${'order.status}; only delivered orders can be refunded`;
    }
    if amount <= 0d {
        return "Refund amount must be greater than zero";
    }
    decimal refundable = 'order.total * maxRefundRatio - 'order.refunded;
    if amount > refundable {
        return string `Refund amount ${amount} exceeds the refundable amount ${refundable}`;
    }
    return ();
}

# Derives the idempotency key for a refund. The key depends only on the order, so a
# retried or replayed call, or a second refund attempt for the same order, cannot
# create a second payment.
#
# + orderId - The order to refund
# + return - The idempotency key
isolated function refundKey(string orderId) returns string => string `refund-${orderId}`;

# Simulates a payment gateway that honors idempotency keys: a request with a key that
# was already accepted returns the original refund ID instead of paying again.
#
# + idempotencyKey - Key that identifies the refund
# + orderId - The order to refund
# + amount - The amount to refund
# + reason - The reason for the refund
# + return - The state of the request, or an error if the gateway is unavailable
isolated function submitRefund(string idempotencyKey, string orderId, decimal amount, string reason)
        returns GatewayRequest|error {
    lock {
        GatewayRequest request = gatewayRequests[idempotencyKey] ?: {attempts: 0, refundId: ()};
        if request.refundId is string {
            log:printInfo("Duplicate refund request ignored", idempotencyKey = idempotencyKey);
            request.duplicate = true;
            return request.clone();
        }
        request.attempts += 1;
        gatewayRequests[idempotencyKey] = request;
        if request.attempts <= gatewayFailuresBeforeSuccess {
            return error(string `Payment gateway unavailable (attempt ${request.attempts})`);
        }
        string refundId = string `RF-${orderId}`;
        request.refundId = refundId;
        log:printInfo("Refund accepted by payment gateway", refundId = refundId, amount = amount,
                reason = reason);
        return request.clone();
    }
}
