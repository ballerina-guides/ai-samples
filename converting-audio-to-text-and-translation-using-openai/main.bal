import ballerina/io;
import ballerinax/openai;

// OpenAI token
configurable string openAIToken = ?;

configurable string audioFilePath = "./audo_clips/german-hello.mp3";
configurable string audioFile = "english-hello.mp3";
configurable string translatingLanguage = "French";

public function main() returns error? {
    openai:OpenAIClient openAI = check new ({auth: {token: openAIToken}});

    // Creates a request to translate the audio file to text (English)
    openai:File file = {
        fileBinary: check io:fileReadBytes(audioFilePath),
        fileName: audioFile
    };
    openai:CreateTranslationRequest translationsReq = {
        file: file,
        model: "whisper-1"
    };

    // Translates the audio file to text (English)
    openai:CreateTranscriptionResponse translationsRes = check openAI->/audio/translations.post(translationsReq);
    io:println(translationsRes.text);

    // Creates a request to translate the text from English to other language
    string prmt = string `Translate the following text from English to ${translatingLanguage} : ${translationsRes.text}`;
    openai:CreateCompletionRequest createCompletionRequest = {
        model: "text-davinci-003",
        prompt: prmt,
        temperature: 0.7,
        max_tokens: 256,
        top_p: 1,
        frequency_penalty: 0,
        presence_penalty: 0
    };

    // Translates the text from English to other language
    openai:CreateCompletionResponse completionRes = check openAI->/completions.post(createCompletionRequest);
    string productDescription = check completionRes.choices[0].text.ensureType();
    io:println(productDescription);
}
