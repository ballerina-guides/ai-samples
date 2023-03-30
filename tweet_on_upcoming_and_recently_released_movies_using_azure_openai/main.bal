import ballerina/io;
import ballerinax/azure.openai.text;
import ballerinax/themoviedb;
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
const MAX_TWEET_LENGTH = 280;
const MAX_TOKENS = 1000;
const NO_OF_MOVIES = 5;

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
        config = {auth: {apiKey: openAIToken}},
        serviceUrl = serviceUrl
    );
    string prompt = "Instruction: Generate a creative and short tweet about upcoming and recently related movies and please include the following. Movies : ";
    int i = 0;
    foreach var movie in result.results {
        i = i + 1;
        prompt += string `${i.toString()}. ${movie.title} - ${movie.overview} `;
        if i == NO_OF_MOVIES {
            break;
        }
    }

    text:Deploymentid_completions_body completionsBody = {
        prompt,
        max_tokens: MAX_TOKENS
    };
    text:Inline_response_200 completion = check azureOpenAI->/deployments/[deploymentId]/completions.post(API_VERSION, completionsBody);
    string? tweetContent = completion.choices[0].text;

    // Tweet it out!
    if tweetContent is string {
        final twitter:Client twitter = check new (twitterConfig);
        if tweetContent.length() > MAX_TWEET_LENGTH {
            var tweet = check twitter->tweet(tweetContent.substring(0, MAX_TWEET_LENGTH));
            io:println("Tweet: ", tweet.text);
        } else {
            var tweet = check twitter->tweet(tweetContent);
            io:println("Tweet: ", tweet.text);
        }
    }
}
