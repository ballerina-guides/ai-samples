import ballerina/ai;

# A customer account.
type Account record {|
    # The account ID
    string accountId;
    # The name of the account holder
    string name;
    # The broadband plan
    string plan;
    # The postcode of the service address
    string postcode;
    # The email address of the account holder. Must not be shown to the customer in chat.
    string contactEmail;
|};

# The network status of a postcode area.
type OutageStatus record {|
    # The postcode of the area
    string postcode;
    # Whether there is a known outage in the area
    boolean outage;
    # The estimated resolution time of the outage
    string estimatedResolution?;
|};

# A support ticket that dispatches a technician.
type Ticket record {|
    # The ticket ID
    string ticketId;
    # The account ID
    string accountId;
    # A summary of the problem
    string summary;
|};

final readonly & map<Account> accounts = {
    "A-100": {
        accountId: "A-100",
        name: "Nimal Perera",
        plan: "Fibre 500",
        postcode: "10350",
        contactEmail: "nimal.perera@example.com"
    },
    "A-200": {
        accountId: "A-200",
        name: "Sara Fernando",
        plan: "Fibre 100",
        postcode: "20400",
        contactEmail: "sara.fernando@example.com"
    }
};

final readonly & map<OutageStatus> outages = {
    "10350": {postcode: "10350", outage: true, estimatedResolution: "today 18:00"}
};

isolated map<Ticket> tickets = {};

# Gets the account of a customer, including the plan and the postcode of the service address.
#
# + accountId - The account ID, in the format `A-<number>`, for example `A-100`
# + return - The account, or an error if no account has the given ID
@ai:AgentTool
isolated function getAccount(string accountId) returns Account|error {
    Account? account = accounts[accountId];
    if account is () {
        return error(string `no account with ID ${accountId}`);
    }
    return account;
}

# Gets the network status of a postcode area. Call this before opening a ticket for a connection problem.
#
# + postcode - The postcode of the service address, taken from the account
# + return - Whether there is a known outage in the area and, if so, the estimated resolution time
@ai:AgentTool
isolated function getOutageStatus(string postcode) returns OutageStatus {
    return outages[postcode] ?: {postcode, outage: false};
}

# Opens a support ticket and dispatches a technician. Only use this for a connection problem when
# there is no known outage in the customer's area.
#
# + accountId - The account ID
# + summary - A one-sentence summary of the problem
# + return - The created ticket, or an error if the account does not exist
@ai:AgentTool
isolated function openSupportTicket(string accountId, string summary) returns Ticket|error {
    if !accounts.hasKey(accountId) {
        return error(string `no account with ID ${accountId}`);
    }
    lock {
        Ticket ticket = {ticketId: string `TCK-${1001 + tickets.length()}`, accountId, summary};
        tickets[ticket.ticketId] = ticket;
        return ticket.clone();
    }
}
