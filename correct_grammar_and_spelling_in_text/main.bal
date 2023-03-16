import ballerina/io;
import ballerinax/openai.text;

configurable string openAIToken = ?;

final text:Client openaiTextClient = check new ({auth: {token: openAIToken}});

public function main() returns error? {

    string filePath = "./data/example.txt";
    string fileContent = check io:fileReadString(filePath);

    text:CreateEditRequest request = {
        input: fileContent,
        instruction: "Fix grammar and spelling mistakes.",
        model: "text-davinci-edit-001"
    };
    text:CreateEditResponse editsRes = check openaiTextClient->/edits.post(request);
    string text = <string>editsRes.choices[0].text;

    io:println(string `Corrected: ${text}`);
}
