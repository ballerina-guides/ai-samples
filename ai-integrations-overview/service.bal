import ballerina/ai;
import ballerina/constraint;
import ballerina/http;
import ballerina/log;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;

final ai:ModelProvider model = check new openai:ModelProvider(openAiApiKey, openai:GPT_4O_MINI);

const MAX_TICKET_LENGTH = 4000;

# A support ticket submitted by a customer.
type Ticket record {|
    # The ticket subject line
    @constraint:String {minLength: 1, maxLength: 200}
    string subject;
    # The full ticket text written by the customer
    @constraint:String {minLength: 1, maxLength: MAX_TICKET_LENGTH}
    string body;
|};

# The classification of a support ticket.
type Triage record {|
    # The area of the business that the ticket is about
    "billing"|"shipping"|"technical"|"account"|"other" category;
    # How urgently the ticket needs attention
    "low"|"medium"|"high" priority;
    # A neutral, one-sentence summary of the customer's problem
    @constraint:String {minLength: 1, maxLength: 300}
    string summary;
|};

# The response returned to the caller.
type TriageResult record {|
    *Triage;
    # The support queue that the ticket is routed to
    string queue;
|};

service /tickets on new http:Listener(8080) {
    resource function post triage(Ticket ticket)
            returns TriageResult|http:BadGateway {
        Triage|error triage = model->generate(`
            Classify the following customer support ticket.
            Choose the priority as high only if the customer cannot use
            the product or is losing money.

            Subject: ${ticket.subject}
            Ticket: ${ticket.body}`);

        if triage is error {
            log:printError("Failed to classify the ticket", triage);
            return <http:BadGateway>{body: "Could not classify the ticket"};
        }

        Triage|error validTriage = constraint:validate(triage);
        if validTriage is error {
            log:printWarn("Model response failed validation", 'error = validTriage);
            return <http:BadGateway>{body: "Could not classify the ticket"};
        }
        return {...validTriage, queue: routeTo(validTriage)};
    }
}

# Selects the support queue for a classified ticket.
#
# + triage - The validated classification of the ticket
# + return - The name of the queue that handles the ticket
isolated function routeTo(Triage triage) returns string {
    if triage.priority == "high" {
        return string `${triage.category}-urgent`;
    }
    if triage.category == "other" {
        return "general";
    }
    return triage.category;
}
