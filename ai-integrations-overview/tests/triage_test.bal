import ballerina/constraint;
import ballerina/test;

@test:Config
function testHighPriorityGoesToUrgentQueue() {
    Triage triage = {category: "billing", priority: "high", summary: "Customer was charged twice."};
    test:assertEquals(routeTo(triage), "billing-urgent");
}

@test:Config
function testOtherCategoryGoesToGeneralQueue() {
    Triage triage = {category: "other", priority: "low", summary: "Customer asks about opening hours."};
    test:assertEquals(routeTo(triage), "general");
}

@test:Config
function testCategoryIsUsedAsQueue() {
    Triage triage = {category: "shipping", priority: "medium", summary: "Parcel is late."};
    test:assertEquals(routeTo(triage), "shipping");
}

@test:Config
function testEmptyTicketBodyIsRejected() {
    Ticket ticket = {subject: "Refund", body: ""};
    Ticket|error result = constraint:validate(ticket);
    test:assertTrue(result is error);
}

@test:Config
function testEmptySummaryIsRejected() {
    Triage triage = {category: "account", priority: "low", summary: ""};
    Triage|error result = constraint:validate(triage);
    test:assertTrue(result is error);
}

@test:Config
function testUnknownCategoryCannotBeBound() {
    json response = {category: "legal", priority: "low", summary: "Asks about terms."};
    test:assertTrue(response.cloneWithType(Triage) is error);
}
