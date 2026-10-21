import ballerina/test;

@test:Config
function testValidTriagePasses() returns error? {
    Triage triage = {category: "BILLING", priority: "HIGH", summary: "Customer was charged twice."};
    test:assertEquals(check validateTriage(triage), triage);
}

@test:Config
function testBlankSummaryIsRejected() {
    Triage triage = {category: "TECHNICAL", priority: "LOW", summary: "   "};
    test:assertTrue(validateTriage(triage) is TriageValidationError);
}

@test:Config
function testLongSummaryIsRejected() {
    Triage triage = {category: "TECHNICAL", priority: "LOW", summary: "".padEnd(201, "a")};
    test:assertTrue(validateTriage(triage) is TriageValidationError);
}

@test:Config
function testRoutingByCategory() {
    test:assertEquals(selectQueue({category: "BILLING", priority: "HIGH", summary: "s"}), "billing");
    test:assertEquals(selectQueue({category: "TECHNICAL", priority: "LOW", summary: "s"}), "technical-support");
    test:assertEquals(selectQueue({category: "ACCOUNT", priority: "MEDIUM", summary: "s"}), "account-management");
    test:assertEquals(selectQueue({category: "OTHER", priority: "LOW", summary: "s"}), "manual-triage");
}

@test:Config
function testUrgentTicketsGoToOnCall() {
    test:assertEquals(selectQueue({category: "BILLING", priority: "URGENT", summary: "s"}), "on-call");
}

@test:Config
function testFallbackRouting() {
    RoutedTicket routed = fallbackRouting({subject: "Cannot log in", body: "The login page shows an error."});
    test:assertEquals(routed, {
        category: "OTHER",
        priority: "MEDIUM",
        summary: "Cannot log in",
        queue: "manual-triage",
        triagedBy: "FALLBACK"
    });
}
