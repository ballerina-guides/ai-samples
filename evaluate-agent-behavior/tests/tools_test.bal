import ballerina/test;

@test:Config
function testGetAccount() returns error? {
    Account account = check getAccount("A-200");
    test:assertEquals(account.postcode, "20400");
}

@test:Config
function testUnknownAccountIsAnError() {
    Account|error account = getAccount("A-999");
    test:assertTrue(account is error);
}

@test:Config
function testOutageStatus() {
    test:assertTrue(getOutageStatus("10350").outage);
    test:assertEquals(getOutageStatus("20400"), {postcode: "20400", outage: false});
}

@test:Config
function testTicketForUnknownAccountIsRejected() {
    Ticket|error ticket = openSupportTicket("A-999", "No connection");
    test:assertTrue(ticket is error);
}
