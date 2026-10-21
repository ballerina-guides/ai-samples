import ballerina/ai;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;
configurable int maxIterations = 5;

final ai:ModelProvider model = check new openai:ModelProvider(openAiApiKey, openai:GPT_4O);

final ai:Agent claimsAgent = check new (
    systemPrompt = {
        role: "Claims Assistant",
        instructions: string `You help policyholders of an insurance company with questions about their claims.

            Rules:
            - Use the tools to look up claims. Never guess a claim status, an amount, or a date.
            - If the user does not give a claim ID, ask for it.
            - Book a callback only when the user asks to speak to an adjuster.
            - Some values in the message are replaced with placeholders such as [EMAIL].
              Do not ask the user to repeat them.
            - Do not answer questions that are not about claims. Keep answers short.`
    },
    model = model,
    tools = [getClaimStatus, requestCallback],
    maxIter = maxIterations
);
