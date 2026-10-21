import ballerina/ai;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;
configurable int maxIterations = 5;

final ai:ModelProvider model = check new openai:ModelProvider(openAiApiKey, openai:GPT_4O);

# Creates the broadband support agent with the given model provider.
#
# + model - The model provider that the agent uses for reasoning
# + return - The agent, or an error if it cannot be created
isolated function createSupportAgent(ai:ModelProvider model) returns ai:Agent|ai:Error {
    return new ai:Agent(
        systemPrompt = {
            role: "Broadband support agent",
            instructions: string `You help customers of a broadband provider with connection problems
                and questions about their account.
                - Always look up the account before answering a question about it.
                - For a connection problem, check the outage status of the account's postcode first.
                  If there is an outage, give the estimated resolution time and do not open a ticket.
                  Otherwise, open a support ticket and give the customer the ticket ID.
                - Never reveal a customer's email address or other contact details.
                - If a question is not about the customer's broadband service, say that you cannot help with it.`
        },
        tools = [getAccount, getOutageStatus, openSupportTicket],
        model = model,
        maxIter = maxIterations
    );
}
