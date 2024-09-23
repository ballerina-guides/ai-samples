import ballerinax/openai.chat;

configurable string openAIToken = ?;

final chat:Client chatClient = check new ({
    auth: {
        token: openAIToken
    }
});

function generateChatCompletion(string prompt, string model = "gpt-4o-mini") returns string|error {
    chat:CreateChatCompletionResponse res = check chatClient->/chat/completions.post({
        model,
        messages: [{role: "user", content: prompt}]
    });
    string? content = res.choices[0]?.message?.content;
    return content ?: error("The message is empty.");
}
