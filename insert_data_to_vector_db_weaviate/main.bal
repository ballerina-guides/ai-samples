import ballerina/io;
import ballerinax/googleapis.sheets;
import ballerinax/openai.embeddings;
import ballerinax/weaviate;

configurable string openAIToken = ?;
configurable string weaviateToken = ?;
configurable string weaviateURL = ?;

configurable string sheetAccessToken = ?;
configurable string sheetId = ?;
configurable string sheetName = ?;

const RANGE = "A2:C630";
const NO_OF_COLUMNS = 3;
const className = "QuestionAnswerStore";
const MODEL = "text-embedding-ada-002";

final embeddings:Client openai = check new ({auth: {token: openAIToken}});
final weaviate:Client weaviate = check new ({auth: {token: weaviateToken}, timeout: 100}, weaviateURL);
final sheets:Client gsheets = check new ({auth: {token: sheetAccessToken}});

public function main() returns error? {
    sheets:Range range = check gsheets->getRange(sheetId, sheetName, RANGE);
    string[] data = [];
    weaviate:Object[] documentObjects = [];
    int j = 0;
    // Iterate through the data stream and extract the content
    foreach var row in range.values {
        if (row.length() != NO_OF_COLUMNS) {
            continue;
        }
        weaviate:Object obj = {
            'class: className,
            properties: {
                title: row[0],
                question: row[1],
                answer: row[2]
            }
        };
        documentObjects.push(obj);
        data.push(row[1].toString());
        j = j + 1;
        if j == 5{
            break;
        }
    }
    embeddings:CreateEmbeddingResponse embeddingResponse = check openai->/embeddings.post({model: MODEL, input: data});
    documentObjects[0]["class"] = "abc";

    // Insert embedding vectors to the Weaviate objects
    foreach int i in 0 ... embeddingResponse.data.length() - 1 {
        documentObjects[i].vector = embeddingResponse.data[i].embedding;
    }

    weaviate:ObjectsGetResponse[] responses = check weaviate->/batch/objects.post({objects: documentObjects});

    string[] failedQuestions = [];
    foreach var res in responses {
        if res.result["errors"]["error"] != () {
            failedQuestions.push(res.properties["question"].toString());
        }
    }
    if failedQuestions.length() > 0 {
        return error("Failed to insert embedding vectors for the questions: " + failedQuestions.toString());  
    }

    io:println("Successfully inserted embedding vectors to the Weaviate vector database.");
}
