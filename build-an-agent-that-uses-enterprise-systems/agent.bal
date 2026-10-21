import ballerina/ai;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;
configurable int memorySize = 20;
configurable int maxIterations = 5;

final ai:ModelProvider model = check new openai:ModelProvider(openAiApiKey, openai:GPT_4O);

// Keeps the most recent messages of each session in memory.
final ai:ShortTermMemory memory = check new (check new ai:InMemoryShortTermMemoryStore(memorySize));

final ai:Agent orderSupportAgent = check new (
    systemPrompt = {
        role: "Order Support Assistant",
        instructions: string `You help customers of an online store with questions about their orders.

            Rules:
            - Use the tools to look up orders and shipments. Never guess an order status,
              a tracking number, or a delivery date.
            - If the customer does not give an order ID, ask for it.
            - Before cancelling an order, describe the order and ask the customer to confirm.
              Call cancelOrder only after the customer confirms.
            - If a tool returns an error, explain the problem to the customer in plain language.
            - Do not answer questions that are not about orders or shipments.
            - Keep answers short.`
    },
    model = model,
    tools = [getOrder, cancelOrder, shipmentToolKit],
    memory = memory,
    maxIter = maxIterations
);
