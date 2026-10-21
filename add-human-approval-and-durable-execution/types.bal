import ballerina/constraint;

# A refund request submitted by the support desk.
type RefundRequest record {|
    # Support ticket that the request belongs to
    @constraint:String {pattern: re `TKT-[0-9]+`}
    string ticketId;
    # Order that the customer wants a refund for
    @constraint:String {pattern: re `ORD-[0-9]+`}
    string orderId;
    # The customer's message, as written
    @constraint:String {minLength: 1, maxLength: 2000}
    string customerMessage;
|};

# An order, as returned by the order system.
type Order record {|
    # The order ID
    string orderId;
    # The customer who placed the order
    string customerId;
    # The fulfillment status of the order
    "DELIVERED"|"SHIPPED"|"CANCELLED" status;
    # The order total
    decimal total;
    # The amount already refunded for the order
    decimal refunded;
|};

# The outcome of a call to the `issueRefund` activity.
type RefundResult record {|
    # `ISSUED` if the payment gateway accepted the refund, `REJECTED` if the refund policy blocked it
    "ISSUED"|"REJECTED" status;
    # The order the refund is for
    string orderId;
    # The requested amount
    decimal amount;
    # Payment gateway reference, present when the refund was issued
    string refundId?;
    # A human-readable explanation of the result
    string message;
|};

# The status of a refund request, as returned to the support desk.
type RefundStatus record {|
    # The instance ID of the refund agent run (the ticket ID)
    string instanceId;
    # Where the run is
    "IN_PROGRESS"|"COMPLETED"|"FAILED"|"NOT_FOUND" status;
    # The agent's final answer, once the run has completed
    string summary?;
|};
