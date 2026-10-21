import ballerina/http;

// A mock of the claims API, so that the sample runs without external systems.
// It accepts only the token that grants each operation.
configurable int claimsApiPort = 9090;

isolated map<Claim> claims = {
    "CLM-10234": {
        claimId: "CLM-10234",
        policyholderId: "PH-001",
        status: "UNDER_REVIEW",
        amountClaimed: 1850.00,
        lastUpdated: "2026-10-02",
        nextStep: "An adjuster is reviewing the repair estimate.",
        email: "alex@example.com",
        bankAccount: "GB33BUKB20201555555555",
        adjusterNotes: "Customer reported a prior claim in 2024."
    },
    "CLM-20871": {
        claimId: "CLM-20871",
        policyholderId: "PH-002",
        status: "APPROVED",
        amountClaimed: 420.00,
        lastUpdated: "2026-09-28",
        nextStep: "Payment is scheduled within five business days.",
        email: "sam@example.com",
        bankAccount: "GB94BARC10201530093459",
        adjusterNotes: "No issues."
    }
};

service /api on new http:Listener(claimsApiPort) {
    resource function get policyholders/[string policyholderId]/claims/[string claimId](
            @http:Header string? authorization) returns Claim|http:Unauthorized|http:NotFound {
        if authorization != string `Bearer ${claimsReadToken}` {
            return <http:Unauthorized>{body: {message: "Invalid token for reading claims"}};
        }
        return findClaim(policyholderId, claimId) ?: <http:NotFound>{body: {message: string `Claim ${claimId} was not found.`}};
    }

    resource function post policyholders/[string policyholderId]/claims/[string claimId]/callbacks(
            @http:Header string? authorization, record {|CallbackWindow window;|} request)
            returns Callback|http:Unauthorized|http:NotFound {
        if authorization != string `Bearer ${callbackWriteToken}` {
            return <http:Unauthorized>{body: {message: "Invalid token for booking callbacks"}};
        }
        if findClaim(policyholderId, claimId) is () {
            return <http:NotFound>{body: {message: string `Claim ${claimId} was not found.`}};
        }
        return {callbackId: string `CB-${claimId.substring(4)}`, claimId, window: request.window};
    }
}

// Returns the claim only if it belongs to the policyholder.
isolated function findClaim(string policyholderId, string claimId) returns Claim? {
    lock {
        Claim? claim = claims[claimId];
        if claim is Claim && claim.policyholderId == policyholderId {
            return claim.clone();
        }
        return;
    }
}
