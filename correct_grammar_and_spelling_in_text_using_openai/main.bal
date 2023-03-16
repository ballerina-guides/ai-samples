import ballerina/http;
import ballerina/io;
import ballerinax/openai.text;

configurable string openAIToken = ?;
configurable string filePath = ?;

public function main() returns error? {
    http:RetryConfig retryConfig = {
        interval: 5, // Initial retry interval in seconds.
        count: 3, // Number of retry attempts before stopping.
        backOffFactor: 2.0 // Multiplier of the retry interval.
    };
    final text:Client openaiText = check new ({auth: {token: openAIToken}, retryConfig});
    string fileContent = check io:fileReadString(filePath);

    text:CreateEditRequest request = {
        input: fileContent,
        instruction: "Fix grammar and spelling mistakes.",
        model: "text-davinci-edit-001"
    };
    text:CreateEditResponse editsRes = check openaiText->/edits.post(request);
    string text = <string>editsRes.choices[0].text;

    io:println(string `Corrected: ${text}`);
}
