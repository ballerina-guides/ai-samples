import ballerina/io;
import ballerinax/openai.finetunes;

configurable string openAIToken = ?;

const string TRAINDATAFILEPATH = "./data/train_prepared.jsonl";
const string TRAINDATAFILENAME = "train_prepared.jsonl";

public function main() returns error? {

    finetunes:Client openaiFineTunes = check new ({auth: {token: openAIToken}});

    byte[] fileContent = check io:fileReadBytes(TRAINDATAFILEPATH);

    finetunes:CreateFileRequest fileRequest = {
        file: {fileContent, TRAINDATAFILENAME},
        purpose: "fine-tune"
    };

    finetunes:OpenAIFile fileResponse = check openaiFineTunes->/files.post(fileRequest);

    io:println("Training file uploaded successfully with ID " + fileResponse.id + ".");

    finetunes:CreateFineTuneRequest fineTuneRequest = {
        training_file: fileResponse.id,
        model: "ada",
        n_epochs: 4
    };

    finetunes:FineTune fineTuneResponse = check openaiFineTunes->/fine\-tunes.post(fineTuneRequest);

    io:println("Fine-tune job started successfully with ID " + fineTuneResponse.id + ".");

}
