import ballerina/ai;
import ballerina/http;
import ballerina/test;

function contextFor(string policyholderId) returns ai:Context {
    ai:Context ctx = new;
    ctx.set(POLICYHOLDER_ID, policyholderId);
    return ctx;
}

@test:Config
function testGetOwnClaim() returns error? {
    ClaimSummary summary = check getClaimStatus(contextFor("PH-001"), "CLM-10234");
    test:assertEquals(summary.status, "UNDER_REVIEW");
}

@test:Config
function testClaimOfAnotherPolicyholderIsNotReturned() {
    ClaimSummary|error result = getClaimStatus(contextFor("PH-001"), "CLM-20871");
    test:assertTrue(result is error);
    if result is error {
        test:assertEquals(result.message(), "Claim CLM-20871 was not found.");
    }
}

@test:Config
function testInvalidClaimIdIsRejected() {
    test:assertTrue(getClaimStatus(contextFor("PH-001"), "10234") is error);
}

@test:Config
function testRequestCallback() returns error? {
    Callback callback = check requestCallback(contextFor("PH-001"), "CLM-10234", MORNING);
    test:assertEquals(callback, {callbackId: "CB-10234", claimId: "CLM-10234", window: MORNING});
}

@test:Config
function testReadCredentialCannotBookCallbacks() returns error? {
    http:Response response =
        check claimsReader->/policyholders/["PH-001"]/claims/["CLM-10234"]/callbacks.post({window: MORNING});
    test:assertEquals(response.statusCode, http:STATUS_UNAUTHORIZED);
}
