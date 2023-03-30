import ballerina/io;
import ballerinax/azure.openai.text;
import ballerinax/medium;

configurable string openAIToken = ?;
configurable string serviceUrl = ?;
configurable string deploymentId = ?;
configurable string mediumToken = ?;

const API_VERSION = "2023-03-15-preview";

public function main(string title) returns error? {
    final medium:Client medium = check new ({auth: {token: mediumToken}});
    final text:Client azureOpenAI = check new (
        config = {auth: {apiKey: openAIToken}},
        serviceUrl = serviceUrl
    );

    medium:UserResponse response = check medium->getUserDetail();
    string? userId = response.data?.id;

    if userId !is string {
        return error("Medium user ID is not valid");
    }

    text:Deploymentid_completions_body completionsBody = {
        prompt: string `Write a blog article on ${title} in markdown format.`,
        max_tokens: 1000
    };
    text:Inline_response_200 completion = check azureOpenAI->/deployments/[deploymentId]/completions.post(API_VERSION, completionsBody);
    string? content = completion.choices[0].text;

    if content !is string {
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
