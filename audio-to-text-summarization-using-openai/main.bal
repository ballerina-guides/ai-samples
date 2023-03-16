import ballerinax/twitter;
import ballerina/io;
import ballerina/http;
import ballerinax/openai.text;
import ballerinax/openai.audio;

configurable string openAIToken = ?;

configurable string apiKey = ?;
configurable string apiSecret = ?;
configurable string accessToken = ?;
configurable string accessTokenSecret = ?;

const string AUDIOFILEPATH = "podcast-clips/test.mp3";
const string AUDIOFILE = "test.mp3";
const string PODCASTURL = "https://cdn.simplecast.com/audio/404a3f47-e74f-4c91-beff-bf2977e22d22/episodes/5b5a2a5c-6334-4bcd-939c-8d25e96ff522/audio/3b66b225-9e44-4656-9cde-920e14c92220/default_tc.mp3?aid=rss_feed&feed=bKMTTEds";
const int BINARYLENGTH = 1000000;

// OpenAI API text client configuration
final text:Client openaiTextClient = check new ({
    auth: {
        token: openAIToken
    }
});

// OpenAI API audio client configuration
final audio:Client openaiAudioClient = check new ({
    auth: {
        token: openAIToken
    }
});

// Twitter API client configuration
twitter:ConnectionConfig twitterConfig = {
    apiKey,
    apiSecret,
    accessToken,
    accessTokenSecret
};
final twitter:Client twitterClient = check new (twitterConfig);

public function main() returns error? {

    // Creates a HTTP client to download the audio file
    http:Client httpClient = check new (PODCASTURL);

    // Downloads the audio file
    http:Response response = check httpClient->/get();
    byte[] listResult = check response.getBinaryPayload();
    check io:fileWriteBytes(AUDIOFILEPATH, listResult);

    // Creates a request to translate the audio file to text (English)
    audio:CreateTranscriptionRequest transcriptionsReq = {
        file: {fileContent: (check io:fileReadBytes(AUDIOFILEPATH)).slice(0, BINARYLENGTH), fileName:AUDIOFILE},
        model: "whisper-1"
    };

    // Converts the audio file to text (English)
    audio:CreateTranscriptionResponse transcriptionsRes = check openaiAudioClient->/audio/transcriptions.post(transcriptionsReq);
    io:println("Text from the audio :", transcriptionsRes.text);

    // Creates a request to summarize the text
    string prmt = "Summarize the following text to 100 characters : " + transcriptionsRes.text;
    text:CreateCompletionRequest createCompletionRequest = {
        model: "text-davinci-003",
        prompt: prmt,
        temperature: 0.7,
        max_tokens: 256,
        top_p: 1,
        frequency_penalty: 0,
        presence_penalty: 0
    };

    // Summarizes the text
    text:CreateCompletionResponse completionRes = check openaiTextClient->/completions.post(createCompletionRequest);
    string summerizedText = check completionRes.choices[0].text.ensureType();
    io:println("Summarized text: ", summerizedText);

    // Creates a tweet
    var result = twitterClient->tweet(summerizedText);
    if (result is twitter:Tweet) {
        io:println("Tweet: ", result.toString());
    } else {
        io:println("Error: ", result.toString());
    }
}
