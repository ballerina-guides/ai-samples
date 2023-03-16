import ballerinax/twitter;
import ballerina/io;
import ballerina/http;
import ballerinax/openai.text;
import ballerinax/openai.audio;

configurable string openAIToken = ?;

configurable string twitterApiKey = ?;
configurable string twitterApiSecret = ?;
configurable string twitterAccessToken = ?;
configurable string twitterAccessTokenSecret = ?;

const string AUDIOFILE = "test.mp3";
const string AUDIOFILEPATH = "podcast-clips/" + AUDIOFILE;
const int BINARYLENGTH = 1000000;

// Twitter API client configuration
twitter:ConnectionConfig twitterConfig = {
    apiKey: twitterApiKey,
    apiSecret: twitterApiSecret,
    accessToken: twitterAccessToken,
    accessTokenSecret: twitterAccessTokenSecret
};

public function main(string podcastURL) returns error? {
    // Creates a HTTP client to download the audio file
    http:Client podcastEP = check new (podcastURL);
    http:Response httpResp = check podcastEP->/get();
    byte[] audioBytes = check httpResp.getBinaryPayload();
    check io:fileWriteBytes(AUDIOFILEPATH, audioBytes);

    // Creates a request to translate the audio file to text (English)
    audio:CreateTranscriptionRequest transcriptionsReq = {
        file: {fileContent: (check io:fileReadBytes(AUDIOFILEPATH)).slice(0, BINARYLENGTH), fileName: AUDIOFILE},
        model: "whisper-1"
    };

    // Converts the audio file to text (English) using OpenAI speach to text API
    audio:Client openAIAudio = check new ({auth: {token: openAIToken}});
    audio:CreateTranscriptionResponse transcriptionsRes = check openAIAudio->/audio/transcriptions.post(transcriptionsReq);
    io:println("Text from the audio :", transcriptionsRes.text);

    // Creates a request to summarize the text
    string prmt = "Summarize the following text to 100 characters : " + transcriptionsRes.text;
    text:CreateCompletionRequest textCompletionReq = {
        model: "text-davinci-003",
        prompt: prmt,
        temperature: 0.7,
        max_tokens: 256,
        top_p: 1,
        frequency_penalty: 0,
        presence_penalty: 0
    };

    // Summarizes the text using OpenAI text completion API
    text:Client openAIText = check new ({auth: {token: openAIToken}});
    text:CreateCompletionResponse completionRes = check openAIText->/completions.post(textCompletionReq);
    string summerizedText = check completionRes.choices[0].text.ensureType();
    io:println("Summarized text: ", summerizedText);

    // Tweet it out!
    twitter:Client twitterClient = check new (twitterConfig);
    var tweet = check twitterClient->tweet(summerizedText);
    io:println("Tweet: ", tweet);
}
