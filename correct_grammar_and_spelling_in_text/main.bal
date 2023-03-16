import ballerina/io;
import ballerinax/openai.text;

configurable string openAIToken = ?;
configurable string filePath = ?;

public function main() returns error? {
    final text:Client openaiTextClient = check new ({auth: {token: openAIToken}});
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
