import ballerina/http;

configurable int backendPort = 9090;

// In-memory data for the mock order and shipment APIs.
isolated map<Order> orders = {
    "ORD-1001": {
        orderId: "ORD-1001",
        status: SHIPPED,
        items: [{sku: "KB-201", name: "Mechanical keyboard", quantity: 1}],
        total: 89.99,
        trackingNumber: "TRK-55501"
    },
    "ORD-1002": {
        orderId: "ORD-1002",
        status: PENDING,
        items: [{sku: "MS-110", name: "Wireless mouse", quantity: 2}],
        total: 49.98
    }
};

final readonly & map<Shipment> shipments = {
    "TRK-55501": {
        trackingNumber: "TRK-55501",
        carrier: "FastShip",
        status: "In transit",
        estimatedDelivery: "2026-10-15"
    }
};

// A mock of the order management and logistics APIs that the agent uses.
// In a real deployment, these are existing enterprise systems.
service /api on new http:Listener(backendPort) {
    resource function get orders/[string orderId]() returns Order|http:NotFound {
        lock {
            Order? 'order = orders[orderId];
            if 'order is () {
                return <http:NotFound>{body: <ErrorBody>{message: string `Order ${orderId} not found`}};
            }
            return 'order.clone();
        }
    }

    resource function post orders/[string orderId]/cancel(CancellationRequest request)
            returns Order|http:NotFound|http:Conflict {
        lock {
            Order? 'order = orders[orderId];
            if 'order is () {
                return <http:NotFound>{body: <ErrorBody>{message: string `Order ${orderId} not found`}};
            }
            if 'order.status != PENDING {
                return <http:Conflict>{
                    body: <ErrorBody>{message: string `Order ${orderId} is ${'order.status} and cannot be cancelled`}
                };
            }
            'order.status = CANCELLED;
            return 'order.clone();
        }
    }

    resource function get shipments/[string trackingNumber]() returns Shipment|http:NotFound {
        Shipment? shipment = shipments[trackingNumber];
        if shipment is () {
            return <http:NotFound>{body: <ErrorBody>{message: string `Shipment ${trackingNumber} not found`}};
        }
        return shipment;
    }
}
