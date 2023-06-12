import ballerinax/openai.chat;

configurable string openAIToken = ?;

chat:Client chatClient = check new ({
    auth: {
        token: openAIToken
    }
});

function generateChatCompletion(string prompt, string model = "gpt-3.5-turbo") returns string|error {
    chat:CreateChatCompletionRequest req = {
        model: model,
        messages: [{"role": "user", "content": prompt}]
    };
    chat:CreateChatCompletionResponse res = check chatClient->/chat/completions.post(req);
    string? content = res.choices[0]?.message["content"];
    if (content == ()) {
        return error("The message is empty.");
    } else {
        return content;
    }
}
