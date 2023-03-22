import ballerina/http;
import ballerina/io;
import ballerinax/openai.text;
import ballerinax/openai.audio;

configurable string openAIToken = ?;

const string AUDIO_FILE = "german_hello.mp3";
const string AUDIO_FILE_PATH = "./audo_clips/" + AUDIO_FILE;

public function main(string audioURL, string toLanguage) returns error? {
    // Creates a HTTP client to download the audio file
    http:Client audioEP = check new (audioURL);
    http:Response httpResp = check audioEP->/get();
    byte[] audioBytes = check httpResp.getBinaryPayload();
    check io:fileWriteBytes(AUDIO_FILE_PATH, audioBytes);

    // Creates a request to translate the audio file to text (English)
    audio:CreateTranslationRequest translationsReq = {
        file: {fileContent: check io:fileReadBytes(AUDIO_FILE_PATH), fileName: AUDIO_FILE},
        model: "whisper-1"
    };

    // Translates the audio file to text (English)
    audio:Client openAIAudio = check new ({auth: {token: openAIToken}});
    audio:CreateTranscriptionResponse transcriptionRes = check openAIAudio->/audio/translations.post(translationsReq);
    io:println("Audio text in English: ", transcriptionRes.text);

    // Creates a request to translate the text from English to another language
    text:CreateCompletionRequest completionReq = {
        model: "text-davinci-003",
        prompt: string `Translate the following text from English to ${toLanguage} : ${transcriptionRes.text}`,
        temperature: 0.7,
        max_tokens: 256,
        top_p: 1,
        frequency_penalty: 0,
        presence_penalty: 0
    };

    // Translates the text from English to another language
    text:Client openAIText = check new ({auth: {token: openAIToken}});
    text:CreateCompletionResponse completionRes = check openAIText->/completions.post(completionReq);
    string? translatedText = completionRes.choices[0].text;

    if translatedText is string { 
	    io:println("Translated text: ", translatedText);
    } else {
        return error("Failed to translate the given audio.");
    }
}
