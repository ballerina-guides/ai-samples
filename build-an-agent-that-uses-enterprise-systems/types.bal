# The status of an order.
enum OrderStatus {
    PENDING,
    SHIPPED,
    DELIVERED,
    CANCELLED
}

# An item in an order.
type OrderItem record {|
    # The stock-keeping unit of the product
    string sku;
    # The product name
    string name;
    # The number of units ordered
    int quantity;
|};

# An order in the order management system.
type Order record {|
    # The order ID, in the format ORD-1234
    string orderId;
    # The current status of the order
    OrderStatus status;
    # The items in the order
    OrderItem[] items;
    # The order total in USD
    decimal total;
    # The tracking number of the shipment, if the order has shipped
    string trackingNumber?;
|};

# A shipment tracked by the logistics system.
type Shipment record {|
    # The tracking number
    string trackingNumber;
    # The carrier delivering the shipment
    string carrier;
    # The latest shipment status
    string status;
    # The estimated delivery date, in YYYY-MM-DD format
    string estimatedDelivery;
|};

# The payload of a cancellation request.
type CancellationRequest record {|
    # The reason given by the customer
    string reason;
|};

# The error payload returned by the backend APIs.
type ErrorBody record {|
    # A description of the error
    string message;
|};
