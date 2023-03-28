import ballerina/http;
import ballerinax/azure_openai.chat;

configurable string openAIToken = ?;
configurable string serviceUrl = ?;
configurable string deploymentId = ?;

const API_VERSION = "2023-03-15-preview";

final chat:Client azureOpenAI = check new (
    config = {httpVersion: http:HTTP_1_1, auth: {apiKey: openAIToken}},
    serviceUrl = serviceUrl
);

type ChatMessage record {|
    string role;
    string content;
|};

service /slack on new http:Listener(8080) {
    map<ChatMessage[]> chatHistory = {};

    resource function post events(@http:Payload map<string> request) returns json|error {
        string? chanelName = request["channel_name"];
        string? requestText = request["text"];
        if chanelName !is string || requestText !is string{
            return error("Error in request");
        }

        ChatMessage[] history = self.chatHistory[chanelName] ?: [];
        if history.length() == 0 {
            history = [{role: "system", content: "You an AI slack bot to assist with user questions."}, {role: "user", content: requestText}];
        } else {
            history.push({role: "user", content: requestText});
        }

        chat:Chat_completions_body chatBody = {messages: history};
        chat:Inline_response_200 completion = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(API_VERSION, chatBody);

        chat:Inline_response_200_message? response = completion.choices[0].message;
        if response !is chat:Inline_response_200_message {
            return error("Error in response generation");
        }

        // Limit history to 25 messages to preserve token limit
        if (history.length() > 25) {
            history = history.slice(1, history.length());
        }
        history.push({role: "assistant", content: response.content});
        self.chatHistory[chanelName] = history;

        string? responseText = response.content;
        if responseText !is string {
            return error("Response text is not a string");
        }

        return {"response_type": "in_channel", "text": responseText};
    }
}
