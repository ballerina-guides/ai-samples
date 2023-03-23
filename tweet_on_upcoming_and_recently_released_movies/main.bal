import ballerina/io;
import ballerinax/themoviedb;
import ballerinax/azure_openai.text;
import ballerina/http;
import ballerinax/twitter;

configurable string moviedbApiKey = ?;

configurable string openAIToken = ?;
configurable string serviceUrl = ?;
configurable string deploymentId = ?;

configurable string twitterApiKey = ?;
configurable string twitterApiSecret = ?;
configurable string twitterAccessToken = ?;
configurable string twitterAccessTokenSecret = ?;

const API_VERSION = "2023-03-15-preview";

// Twitter API client configuration
twitter:ConnectionConfig twitterConfig = {
    apiKey: twitterApiKey,
    apiSecret: twitterApiSecret,
    accessToken: twitterAccessToken,
    accessTokenSecret: twitterAccessTokenSecret
};

public function main() returns error? {
    // Get information on upcoming and recently released movies from TMDB
    final themoviedb:Client moviedb = check new themoviedb:Client({apiKey : moviedbApiKey});
    themoviedb:InlineResponse2001 result = check moviedb->getUpcomingMovies();

    // Generate a tweet about five movies using Azure OpenAI   
    final text:Client azureOpenAI = check new (
        config = {httpVersion: http:HTTP_1_1, auth: {apiKey: openAIToken}},
        serviceUrl = serviceUrl
    );
    string prompt = "Instruction: Generate a creative and descriptive tweet about upcoming and recently related movies and please include the following. Movies : ";
    int i = 0;
    foreach var movie in result.results{
        i = i + 1;
        prompt += i.toString() + ". " + movie.title + " - " + movie.overview + " ";
        if i == 5 {
            break;
        }
    }

    text:Deploymentid_completions_body completionsBody = {
        prompt,
        max_tokens: 1000
    };
    text:Inline_response_200 completion = check azureOpenAI->/deployments/[deploymentId]/completions.post(API_VERSION, completionsBody);
    string? tweetContent = completion.choices[0].text;

    // Tweet it out!
    if tweetContent is string{ 
        twitter:Client twitter = check new (twitterConfig);
        var tweet = check twitter->tweet(tweetContent);
        io:println("Tweet: ", tweet.text);
    }
}