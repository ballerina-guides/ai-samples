import ballerina/io;
import ballerinax/openai.finetunes;

configurable string openAIToken = ?;

const string TRAIN_DATA_FILE_NAME = "train_prepared.jsonl";
const string TRAIN_DATA_FILE_PATH = "./data/" + TRAIN_DATA_FILE_NAME;

public function main() returns error? {
    finetunes:Client openAIFineTunes = check new ({auth: {token: openAIToken}});

    finetunes:CreateFileRequest fileRequest = {
        file: {
            fileContent: check io:fileReadBytes(TRAIN_DATA_FILE_PATH),
            fileName: TRAIN_DATA_FILE_NAME
        },
        purpose: "fine-tune"
    };
    
    finetunes:OpenAIFile fileResponse = check openAIFineTunes->/files.post(fileRequest);
    io:println(string `Training file uploaded successfully with ID: ${fileResponse.id}`);
        
    finetunes:CreateFineTuningJobRequest fineTuneRequest = {
        training_file: fileResponse.id,
        model: "gpt-3.5-turbo",
        seed: 4
    };

    finetunes:FineTuningJob fineTuneResponse = check openAIFineTunes->/fine_tuning/jobs.post(fineTuneRequest);
    io:println(string `Fine-tune job started successfully with ID: ${fineTuneResponse.id}`);
}