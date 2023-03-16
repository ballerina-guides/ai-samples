import ballerina/io;
import ballerinax/openai.text;
import ballerinax/openai.audio;

configurable string openAIKey = ?;

const string AUDIOFILEPATH = "./audo_clips/german-hello.mp3";
const string AUDIOFILE = "german-hello.mp3";
const string TRANSLATINGLANGUAGE = "French";

// OpenAI API audio client configuration
audio:Client openaiAudioClient = check new ({
    auth: {
        token: openAIKey
    }
});

// OpenAI API client configuration
text:Client openaiTextClient = check new ({
    auth: {
        token: openAIKey
    }
});

public function main() returns error? {

    // Creates a request to translate the audio file to text (English)
    audio:CreateTranslationRequest translationsReq = {
        file: {fileContent: check io:fileReadBytes(AUDIOFILEPATH), fileName: AUDIOFILE},
        model: "whisper-1"
    };

    audio:CreateTranscriptionResponse translationsRes = check openaiAudioClient->/audio/translations.post(translationsReq);
    io:println("Audio text in English: ", translationsRes.text);

    // Creates a request to translate the text from English to other language
    string prmt = "Translate the following text from English to " + TRANSLATINGLANGUAGE + ": " + translationsRes.text;
    text:CreateCompletionRequest createCompletionRequest = {
        model: "text-davinci-003",
        prompt: prmt,
        temperature: 0.7,
        max_tokens: 256,
        top_p: 1,
        frequency_penalty: 0,
        presence_penalty: 0
    };

    // Translates the text from English to other language
    text:CreateCompletionResponse completionRes = check openaiTextClient->/completions.post(createCompletionRequest);
    string productDescription = check completionRes.choices[0].text.ensureType();
    io:println("Translated text: ", productDescription);
}
