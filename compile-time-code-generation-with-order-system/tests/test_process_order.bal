import ballerina/http;
import ballerina/test;

final http:Client shopClient = check new ("http://localhost:8080/shop");
final OrderRequest[] testOrderRequests = getTestOrderRequests();

function getTestOrderRequests() returns OrderRequest[] =>
    const natural {
        Generate list of order requests with:
        - productId: Random id starts with PROD and INVALID, example: PROD001, PROD002, INVALID001
        - quantity: Random integer between 0 and 10
    };

@test:Config
function testProcessOrderRequests() returns error? {
    foreach OrderRequest request in testOrderRequests {
        check testProcessOrderFlow(request);
    }
}

function testProcessOrderFlow(OrderRequest request) returns error? {
    http:Response res = check shopClient->/orders.post(request);
    Product[] filteredOrders = products.filter(p => p.id == request.productId);
    if filteredOrders.length() == 0 {
        test:assertEquals(res.statusCode, http:STATUS_BAD_REQUEST);
        test:assertEquals(res.getTextPayload(), "Product not found");
        return;
    }

    if request.quantity > filteredOrders[0].stock {
        test:assertEquals(res.statusCode, http:STATUS_BAD_REQUEST);
        test:assertEquals(res.getTextPayload(), "Not enough stock available");
        return;
    }

    test:assertEquals(res.statusCode, http:STATUS_CREATED);
}
