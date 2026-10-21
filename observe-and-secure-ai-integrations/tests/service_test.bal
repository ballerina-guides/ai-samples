import ballerina/ai;
import ballerina/http;
import ballerina/jwt;
import ballerina/test;

final http:Client assistant = check new ("http://localhost:18480/assistant");

function issueToken(string scope, string audience = "claims-assistant") returns string|error {
    return jwt:issue({
        issuer: "https://idp.example.com",
        audience,
        username: "PH-001",
        customClaims: {scope},
        signatureConfig: {config: {keyFile: "tests/resources/private.key"}}
    });
}

@test:Config
function testRequestWithoutTokenIsRejected() returns error? {
    http:Response response = check assistant->/chat.post({sessionId: "s1", message: "Hi"});
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
}

@test:Config
function testTokenForAnotherAudienceIsRejected() returns error? {
    string token = check issueToken("claims:assist", "another-api");
    http:Response response = check assistant->/chat.post({sessionId: "s1", message: "Hi"},
        {"Authorization": "Bearer " + token});
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
}

@test:Config
function testTokenWithoutScopeIsForbidden() returns error? {
    string token = check issueToken("profile");
    http:Response response = check assistant->/chat.post({sessionId: "s1", message: "Hi"},
        {"Authorization": "Bearer " + token});
    test:assertEquals(response.statusCode, http:STATUS_FORBIDDEN);
}

@test:Config
function testAuthorizedInvalidRequestIsRejectedBeforeTheModelIsCalled() returns error? {
    string token = check issueToken("claims:assist");
    http:Response response = check assistant->/chat.post({sessionId: "s1", message: "   "},
        {"Authorization": "Bearer " + token});
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);
}

@test:Config
function testModelConnectionFailureIsDetected() {
    ai:Error err = error ai:Error("Unable to obtain valid answer from the agent",
        steps = [error ai:LlmConnectionError("Error while connecting to the model")]);
    test:assertTrue(isModelUnavailable(err));
    test:assertFalse(isModelUnavailable(error ai:Error("Unable to obtain valid answer from the agent", steps = [])));
}
