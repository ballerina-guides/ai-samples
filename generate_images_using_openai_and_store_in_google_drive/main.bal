import ballerina/lang.array;
import ballerinax/googleapis.drive;
import ballerinax/googleapis.sheets;
import ballerinax/openai.images;

configurable string googleAccessToken = ?;
configurable string openAIToken = ?;
configurable string sheetId = ?;
configurable string sheetName = ?;
configurable string gDriveFolderId = ?;

final sheets:Client gSheets = check new ({auth: {token: googleAccessToken}});
final images:Client openaiImages = check new ({auth: {token: openAIToken}});
final drive:Client gDrive = check new ({auth: {token: googleAccessToken}});

public function main() returns error? {
    sheets:Column range = check gSheets->getColumn(sheetId, sheetName, "A");

    foreach (int|string|decimal) cell in range.values {
        string prompt = check cell.ensureType(string);
        images:CreateImageRequest imagePrompt = {
            prompt,
            response_format: "b64_json"
        };
        images:ImagesResponse imageRes = check openaiImages->/images/generations.post(imagePrompt);
        string? encodedImage = imageRes.data[0].b64_json;
        if encodedImage !is string {
            return error("Image URL is not a string");
        }

        // Decode the Base64 string and store image in Google Drive
        byte[] imageBytes = check array:fromBase64(encodedImage);
        _ = check gDrive->uploadFileUsingByteArray(imageBytes, string `${prompt}.png`, gDriveFolderId);

    }
}
