import ballerina/crypto;
import ballerina/http;
import ballerinax/azure.openai.chat;

configurable string openAIToken = ?;
configurable string serviceUrl = ?;
configurable string deploymentId = ?;
configurable string slackSigningSecret = ?;

const API_VERSION = "2023-03-15-preview";
const MAX_MESSAGES = 25;

final chat:Client azureOpenAI = check new (
    config = {auth: {apiKey: openAIToken}},
    serviceUrl = serviceUrl
);

type ChatMessage record {|
    string role;
    string content;
|};

type Response record {|
    string response_type;
    string text;
|};

enum ROLE {
    SYSTEM = "system",
    USER = "user",
    ASSISTANT = "assistant"
}

service /slack on new http:Listener(8080) {
    map<ChatMessage[]> chatHistory = {};

    resource function post events(http:Request request) returns Response|error {
        if !check verifyRequest(request) {
            return error("Request verification failed");
        }

        map<string> requestPayload = check request.getFormParams();

        string? channelName = requestPayload["channel_name"];
        string? requestText = requestPayload["text"];
        if channelName is () || requestText is () {
            return error("Invalid values in the request payload for channel_name or text");
        }

        ChatMessage[] history = self.chatHistory[channelName] ?:
                                [{role: SYSTEM, content: "You are an AI slack bot to assist with user questions."}];
        history.push({role: USER, content: requestText});

        chat:Chat_completions_body chatBody = {messages: history};
        chat:Inline_response_200 completion = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
            API_VERSION, chatBody
        );

        chat:Inline_response_200_message? response = completion.choices[0].message;
        if response is () {
            return error("Error in response generation");
        }

        // Limit history to 25 messages to preserve token limit.
        if history.length() > MAX_MESSAGES {
            history = history.slice(1, history.length());
        }
        history.push({role: ASSISTANT, content: response.content});
        self.chatHistory[channelName] = history;

        string? responseText = response.content;
        if responseText is () {
            return error("Error generating the response");
        }

        return {"response_type": "in_channel", "text": responseText};
    }
}

public function verifyRequest(http:Request request) returns boolean|error {
    string requestBody = check request.getTextPayload();
    string signature = check request.getHeader("X-Slack-Signature");
    string timestamp = check request.getHeader("X-Slack-Request-Timestamp");

    string baseString = string `v0:${timestamp}:${requestBody}`;
    byte[] reqSignature = check crypto:hmacSha256(baseString.toBytes(), slackSigningSecret.toBytes());
    return signature == string `v0=${reqSignature.toBase16()}`;
}
