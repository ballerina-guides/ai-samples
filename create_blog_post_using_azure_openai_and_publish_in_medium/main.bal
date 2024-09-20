import ballerina/io;
import ballerinax/azure.openai.chat;
import ballerinax/medium;

configurable string openAIToken = ?;
configurable string serviceUrl = ?;
configurable string deploymentId = ?;
configurable string mediumToken = ?;

const API_VERSION = "2023-03-15-preview";

public function main(string title) returns error? {
    final medium:Client medium = check new ({auth: {token: mediumToken}});
    medium:UserResponse userResponse = check medium->getUserDetail();
    string? userId = userResponse.data?.id;

    if userId is () {
        return error("Medium user ID is not valid");
    }

    final chat:Client chatClient = check new (
        config = {auth: {apiKey: openAIToken}},
        serviceUrl = serviceUrl
    );

    string prompt = string `Write a blog article on ${title} in markdown format.`;

    chat:CreateChatCompletionRequest chatBody = {
        messages: [{"role": "user", "content": prompt}]  
    };

    chat:CreateChatCompletionResponse completion = check chatClient->/deployments/[deploymentId]/chat/completions.post("2023-12-01-preview", chatBody);

    record {|chat:ChatCompletionResponseMessage message?; chat:ContentFilterChoiceResults content_filter_results?; int index?; string finish_reason?; anydata...;|}[] choices = check completion.choices.ensureType();       

    string? content = choices[0].message?.content;

    if content is () {
        return error("Failed to generate the content for the blog");
    }

    medium:Post post = {
        title,
        contentFormat: "markdown",
        content
    };
    medium:PostResponse postResponse = check medium->createUserPost(userId, post);
    io:println(string `Blog post URL - ${postResponse.data?.url ?: "URL not found."}`);
}
