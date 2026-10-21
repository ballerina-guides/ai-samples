import ballerina/time;

# A product in the catalog.
type Product record {|
    # Stock keeping unit (SKU) that identifies the product
    string sku;
    # Display name of the product
    string name;
    # Unit price in USD
    decimal price;
    # Number of units available to ship
    int unitsInStock;
|};

# Order lifecycle states.
type OrderState "PROCESSING"|"SHIPPED"|"DELIVERED"|"CANCELLED";

# An order as stored in the order management system.
type Order record {|
    # Order ID
    string orderId;
    # Email address of the customer
    string customerEmail;
    # Current state of the order
    OrderState state;
    # SKUs of the items in the order
    string[] skus;
    # Date on which the order was placed (YYYY-MM-DD)
    string placedOn;
    # Date on which the order was delivered (YYYY-MM-DD)
    string? deliveredOn;
|};

# The order details that are shared with clients. Customer contact data is left out.
type OrderStatus record {|
    # Order ID, such as `ORD-1001`
    string orderId;
    # Current state of the order
    OrderState state;
    # SKUs of the items in the order
    string[] skus;
    # Date on which the order was placed (YYYY-MM-DD)
    string placedOn;
    # Date on which the order was delivered (YYYY-MM-DD), if it has been delivered
    string? deliveredOn;
|};

# A return request created for a delivered order.
type ReturnRequest record {|
    # Return request ID, such as `RET-1`
    string returnId;
    # Order ID that the return is for
    string orderId;
    # Reason given by the customer
    string reason;
    # Date and time at which the request was created (RFC 3339)
    string createdAt;
|};

# A refund issued for an order.
type Refund record {|
    # Order ID that the refund is for
    string orderId;
    # Refunded amount in USD
    decimal amount;
|};

# An expected business outcome that is not a success, such as an unknown order.
# Tools return this as a value so that the agent can explain the outcome to the user.
type ToolMessage record {|
    # Machine-readable outcome
    "NOT_FOUND"|"INVALID_INPUT"|"NOT_ALLOWED" outcome;
    # Human-readable explanation
    string message;
|};

const MAX_SEARCH_RESULTS = 5;
const MAX_REASON_LENGTH = 500;

final readonly & Product[] products = [
    {sku: "HP-100", name: "Wireless headphones", price: 79.99, unitsInStock: 12},
    {sku: "HP-200", name: "Noise-cancelling wireless headphones", price: 199.00, unitsInStock: 0},
    {sku: "SP-300", name: "Portable Bluetooth speaker", price: 49.50, unitsInStock: 30},
    {sku: "CB-400", name: "USB-C charging cable", price: 9.99, unitsInStock: 250}
];

final readonly & map<Order> orders = {
    "ORD-1001": {orderId: "ORD-1001", customerEmail: "ann@example.com", state: "DELIVERED",
        skus: ["HP-100"], placedOn: "2026-09-20", deliveredOn: "2026-09-24"},
    "ORD-1002": {orderId: "ORD-1002", customerEmail: "raj@example.com", state: "SHIPPED",
        skus: ["SP-300", "CB-400"], placedOn: "2026-10-05", deliveredOn: ()},
    "ORD-1003": {orderId: "ORD-1003", customerEmail: "li@example.com", state: "PROCESSING",
        skus: ["CB-400"], placedOn: "2026-10-09", deliveredOn: ()}
};

isolated map<ReturnRequest> returnRequests = {};

# Searches the catalog for products whose name contains the given text.
#
# + query - Text to search for
# + return - Matching products, or a `ToolMessage` if the query is invalid
isolated function findProducts(string query) returns Product[]|ToolMessage {
    string term = query.trim().toLowerAscii();
    if term.length() < 2 {
        return {outcome: "INVALID_INPUT", message: "The search text must have at least 2 characters"};
    }
    Product[] matches = from Product product in products
        where product.name.toLowerAscii().includes(term)
        limit MAX_SEARCH_RESULTS
        select product;
    return matches;
}

# Returns the status of an order without customer contact data.
#
# + orderId - The order ID
# + return - The order status, or a `ToolMessage` if the order ID is invalid or unknown
isolated function findOrderStatus(string orderId) returns OrderStatus|ToolMessage {
    ToolMessage? invalid = validateOrderId(orderId);
    if invalid is ToolMessage {
        return invalid;
    }
    Order? 'order = orders[orderId];
    if 'order is () {
        return {outcome: "NOT_FOUND", message: string `No order found with ID ${orderId}`};
    }
    return {
        orderId: 'order.orderId,
        state: 'order.state,
        skus: 'order.skus,
        placedOn: 'order.placedOn,
        deliveredOn: 'order.deliveredOn
    };
}

# Creates a return request for a delivered order. Only one return request is allowed per order.
#
# + orderId - The order ID
# + reason - The reason for the return
# + return - The return request, or a `ToolMessage` if the request is not allowed
isolated function createReturnRequest(string orderId, string reason) returns ReturnRequest|ToolMessage {
    OrderStatus|ToolMessage status = findOrderStatus(orderId);
    if status is ToolMessage {
        return status;
    }
    if status.state != "DELIVERED" {
        return {
            outcome: "NOT_ALLOWED",
            message: string `Order ${orderId} is ${status.state}. Only delivered orders can be returned.`
        };
    }
    string trimmedReason = reason.trim();
    if trimmedReason.length() == 0 || trimmedReason.length() > MAX_REASON_LENGTH {
        return {
            outcome: "INVALID_INPUT",
            message: string `The reason must have between 1 and ${MAX_REASON_LENGTH} characters`
        };
    }
    lock {
        ReturnRequest? existing = returnRequests[orderId];
        if existing is ReturnRequest {
            return {
                outcome: "NOT_ALLOWED",
                message: string `Return request ${existing.returnId} already exists for order ${orderId}`
            };
        }
        ReturnRequest request = {
            returnId: string `RET-${returnRequests.length() + 1}`,
            orderId,
            reason: trimmedReason,
            createdAt: time:utcToString(time:utcNow())
        };
        returnRequests[orderId] = request;
        return request.cloneReadOnly();
    }
}

# Issues a full refund for an order. This is a back-office operation.
#
# + orderId - The order ID
# + return - The refund, or a `ToolMessage` if the order ID is invalid or unknown
isolated function createRefund(string orderId) returns Refund|ToolMessage {
    ToolMessage? invalid = validateOrderId(orderId);
    if invalid is ToolMessage {
        return invalid;
    }
    Order? 'order = orders[orderId];
    if 'order is () {
        return {outcome: "NOT_FOUND", message: string `No order found with ID ${orderId}`};
    }
    decimal amount = 0;
    foreach string sku in 'order.skus {
        foreach Product product in products {
            if product.sku == sku {
                amount += product.price;
            }
        }
    }
    return {orderId, amount};
}

isolated function validateOrderId(string orderId) returns ToolMessage? {
    if !re `ORD-[0-9]{4}`.isFullMatch(orderId) {
        return {outcome: "INVALID_INPUT", message: "Order IDs have the format ORD-NNNN, such as ORD-1001"};
    }
    return ();
}
