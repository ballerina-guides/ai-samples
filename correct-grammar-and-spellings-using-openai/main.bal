import ballerina/io;
import ballerinax/openai.gpt3;

configurable string openAIToken = ?;

final gpt3:Client gpt3Client = check new ({auth: {token: openAIToken}});

public function main() returns error? {

    string filePath = "./data/example.txt";
    string fileContent = check io:fileReadString(filePath);

    gpt3:CreateEditRequest request = {
        input: fileContent,
        instruction: "Fix grammar and spelling mistakes.",
        model: "text-davinci-edit-001"
    };
    gpt3:CreateEditResponse editsRes = check gpt3Client->/edits.post(request);
    string text = <string>editsRes.choices[0].text;

    io:println(string `Corrected: ${text}`);
}
