import ballerina/ai;
import ballerina/http;
import ballerina/log;

configurable string orderApiUrl = "http://localhost:9090/api";

const BACKEND_UNAVAILABLE = "backendUnavailable";
const MAX_REASON_LENGTH = 200;

final http:Client orderApi = check new (orderApiUrl, timeout = 10);

# Retrieves an order, including its status, items, total, and tracking number.
#
# + ctx - The agent context, used to report backend outages to the caller
# + orderId - The order ID, in the format ORD-1234
# + return - The order, or an error that describes why it could not be retrieved
@ai:AgentTool
isolated function getOrder(ai:Context ctx, string orderId) returns Order|error {
    check validateOrderId(orderId);
    Order|http:ClientError 'order = orderApi->/orders/[orderId];
    if 'order is http:ClientError {
        return toToolError(ctx, 'order);
    }
    return 'order;
}

# Cancels an order. Only orders in the PENDING status can be cancelled.
# Call this only after the customer has explicitly confirmed the cancellation.
#
# + ctx - The agent context, used to report backend outages to the caller
# + orderId - The order ID, in the format ORD-1234
# + reason - The reason for the cancellation, as stated by the customer
# + return - The updated order, or an error that describes why it could not be cancelled
@ai:AgentTool
isolated function cancelOrder(ai:Context ctx, string orderId, string reason) returns Order|error {
    check validateOrderId(orderId);
    string trimmedReason = reason.trim();
    if trimmedReason.length() == 0 || trimmedReason.length() > MAX_REASON_LENGTH {
        return error(string `The reason must contain 1 to ${MAX_REASON_LENGTH} characters.`);
    }
    Order|http:ClientError 'order = orderApi->/orders/[orderId]/cancel.post({reason: trimmedReason});
    if 'order is http:ClientError {
        return toToolError(ctx, 'order);
    }
    return 'order;
}

// Exposes the read-only shipment tracking API as a tool, without writing a function for it.
final ai:HttpServiceToolKit shipmentToolKit = check new (orderApiUrl, [
    {
        name: "getShipment",
        description: "Retrieves the carrier, status, and estimated delivery date of a shipment. " +
            "Use the trackingNumber field of the order.",
        method: ai:GET,
        path: "/shipments/{trackingNumber}",
        parameters: {
            trackingNumber: {
                location: ai:PATH,
                description: "The tracking number, in the format TRK-12345",
                schema: {'type: ai:STRING, pattern: "^TRK-[0-9]{5}$"}
            }
        }
    }
]);

# Validates an order ID before it is sent to the backend.
#
# + orderId - The order ID provided by the model
# + return - An error if the order ID is not in the format ORD-1234
isolated function validateOrderId(string orderId) returns error? {
    if !re `ORD-[0-9]{4}`.isFullMatch(orderId) {
        return error(string `'${orderId}' is not a valid order ID. Order IDs have the format ORD-1234.`);
    }
}

# Converts a backend error into an error message for the model.
# Client errors (4xx) describe a problem that the model can explain to the customer.
# Any other failure means the backend is unavailable; it is recorded in the context
# so that the service can fail the request instead of relying on the model's answer.
#
# + ctx - The agent context
# + err - The error returned by the HTTP client
# + return - The error to return to the model
isolated function toToolError(ai:Context ctx, http:ClientError err) returns error {
    if err is http:ClientRequestError {
        ErrorBody|error body = err.detail().body.ensureType();
        return error(body is ErrorBody ? body.message : "The request was rejected by the order system.");
    }
    log:printError("Order API call failed", err);
    ctx.set(BACKEND_UNAVAILABLE, true);
    return error("The order system is unavailable. Do not retry.");
}
