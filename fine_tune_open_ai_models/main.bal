import ballerina/io;
import ballerinax/openai.finetunes;

configurable string openAIKey = ?;
configurable string trainFilePath = ?;

public function main() returns error? {

    finetunes:Client finetunesClient = check new ({
        auth: {
            token: openAIKey
        }
    });

    byte[] fileContent = check io:fileReadBytes(trainFilePath);
    string fileName = "train_prepared.jsonl";

    finetunes:CreateFileRequest fileRequest = {
        file: {fileContent, fileName},
        purpose: "fine-tune"
    };

    finetunes:OpenAIFile fileResponse = check finetunesClient->/files.post(fileRequest);

    io:println("Training file uploaded successfully with ID " + fileResponse.id + ".");

    finetunes:CreateFineTuneRequest fineTuneRequest = {
        training_file: fileResponse.id,
        model: "ada",
        n_epochs: 4
    };

    finetunes:FineTune fineTuneResponse = check finetunesClient->/fine\-tunes.post(fineTuneRequest);

    io:println("Fine tune job started successfully with ID " + fineTuneResponse.id + ".");

}