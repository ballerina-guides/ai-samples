import ballerina/io;
import ballerinax/azure.openai.chat;
import ballerinax/themoviedb;
import ballerinax/twitter;

configurable string moviedbApiKey = ?;

configurable string openAIToken = ?;
configurable string serviceUrl = ?;
configurable string deploymentId = ?;

configurable string token = ?;

const API_VERSION = "2023-03-15-preview";
const MAX_TWEET_LENGTH = 280;
const MAX_TOKENS = 1000;
const NO_OF_MOVIES = 5;

public function main() returns error? {
    // Get information on upcoming and recently released movies from TMDB
    final themoviedb:Client moviedb = check new themoviedb:Client({apiKey: moviedbApiKey});
    themoviedb:InlineResponse2001 upcomingMovies = check moviedb->getUpcomingMovies();

    // Generate a creative tweet using Azure OpenAI   
    string prompt = "Instruction: Generate a creative and short tweet below 250 characters about the following " +
    "upcoming and recently released movies. Movies: ";
    foreach int i in 1 ... NO_OF_MOVIES {
        prompt += string `${i}. ${upcomingMovies.results[i - 1].title} `;
    }

    final twitter:Client twitter = check new ({
        auth: {token: token}
    });

    final chat:Client chatClient = check new (config = {auth: {apiKey: openAIToken}}, serviceUrl = serviceUrl);

    chat:CreateChatCompletionRequest chatBody = {
        messages: [{role: "user", "content": prompt}]
    };

    chat:CreateChatCompletionResponse chatResult = check chatClient->/deployments/[deploymentId]/chat/completions.post("2023-12-01-preview", chatBody);
    record {|chat:ChatCompletionResponseMessage message?; chat:ContentFilterChoiceResults content_filter_results?; int index?; string finish_reason?; anydata...;|}[] choices = check chatResult.choices.ensureType();
    string? tweetContent = choices[0].message?.content;

    if tweetContent is () {
        return error("Failed to generate a tweet on upcoming and recently released movies.");
    }

    if tweetContent.length() > MAX_TWEET_LENGTH {
        return error("The generated tweet exceeded the maximum supported character length.");
    }

    // Tweet it out!
    twitter:TweetCreateResponse tweet = check twitter->/tweets.post(payload = {text: tweetContent});
    io:println("Tweet: ", tweet);
}
