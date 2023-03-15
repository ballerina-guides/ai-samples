import ballerina/io;
import ballerinax/openai.gpt3;

// OpenAI token
configurable string openAIToken = ?;

// Configure OpenAI gpt3 client
gpt3:Client gpt3Client = check new ({
    auth: {
        token: openAIToken
    }
});

public function main() returns error? {

    string filePath = "./data/example.txt";
    string fileContent = check io:fileReadString(filePath);

    string prompt = "Summarize:\n" + fileContent;

    gpt3:CreateCompletionRequest textPrompt = {
        prompt: prompt,
        model: "text-davinci-003",
        max_tokens: 150
    };
    gpt3:CreateCompletionResponse completionRes = check gpt3Client->/completions.post(textPrompt);

    string summary = <string>completionRes.choices[0].text;

    io:println("Content:\n", fileContent, "\n\nSummary:\n", summary);
}
