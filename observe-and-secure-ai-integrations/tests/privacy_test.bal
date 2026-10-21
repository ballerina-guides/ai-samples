import ballerina/test;

@test:Config
function testEmailAndPhoneAreRedacted() {
    [string, int] [redacted, count] =
        redactPii("Reach me at alex@example.com or +44 20 7946 0958 about CLM-10234.");
    test:assertEquals(redacted, "Reach me at [EMAIL] or [PHONE_NUMBER] about CLM-10234.");
    test:assertEquals(count, 2);
}

@test:Config
function testCardNumberIsRedacted() {
    [string, int] [redacted, count] = redactPii("I paid with 4111 1111 1111 1111.");
    test:assertEquals(redacted, "I paid with [CARD_NUMBER].");
    test:assertEquals(count, 1);
}

@test:Config
function testMessageWithoutPiiIsUnchanged() {
    string message = "What is the status of CLM-10234?";
    test:assertEquals(redactPii(message), [message, 0]);
}

@test:Config
function testClaimSummaryExcludesSensitiveFields() {
    Claim claim = {
        claimId: "CLM-10234",
        policyholderId: "PH-001",
        status: "UNDER_REVIEW",
        amountClaimed: 1850.00,
        lastUpdated: "2026-10-02",
        nextStep: "An adjuster is reviewing the repair estimate.",
        email: "alex@example.com",
        bankAccount: "GB33BUKB20201555555555",
        adjusterNotes: "Internal note."
    };
    map<json> summary = <map<json>>toClaimSummary(claim).toJson();
    test:assertEquals(summary.keys(), ["claimId", "status", "amountClaimed", "lastUpdated", "nextStep"]);
}
