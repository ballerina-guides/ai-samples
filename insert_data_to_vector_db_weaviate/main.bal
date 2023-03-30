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

const RANGE = "A:C";
const NO_OF_COLUMNS = 3;
const NO_OF_DATA_SAMPLES = 10; 
string className = "QuestionAnswerStore";

final embeddings:Client openaiClient = check new ({auth: {token: openAIToken}});
final weaviate:Client weaviateClient = check new ({auth: {token: weaviateToken}}, weaviateURL);
final sheets:Client gsheets = check new ({auth: {token: sheetAccessToken}});

public function main() returns error? {

    sheets:Range range = check gsheets->getRange(sheetId, sheetName, RANGE);

    string[] textArr = [];
    weaviate:Object[] documentObjectArray = [];

    // Iterate through the stream and extract the content
    int j = 0;
    foreach var row in range.values {
        if (row.length() == NO_OF_COLUMNS) && (j != 0) {
            weaviate:Object obj = {
            'class: className,
            properties: {
                "title": row[0],
                "question": row[1],
                "answer": row[2]
                }
            };
            documentObjectArray.push(obj);
            textArr.push(row[1].toString());  
        } 
	j = j + 1;
        if (j > NO_OF_DATA_SAMPLES) {
            break;
        }
    }

    embeddings:CreateEmbeddingResponse embeddingRes = check openaiClient->/embeddings.post({model: "text-embedding-ada-002", input: textArr});

    // Insert embedding vectors to the Weaviate objects
    foreach int i in 0 ... embeddingRes.data.length() - 1 {
        documentObjectArray[i].vector = embeddingRes.data[i].embedding;
    }

    weaviate:ObjectsGetResponse[] responseArray = check weaviateClient->/batch/objects.post({objects:documentObjectArray});

    foreach var res in responseArray {
	if res.vector !is weaviate:C11yVector {
            return error("Failed to insert embedding vectors to Weaviate vector database");
        } 
    }

    io:println(string `Successfully inserted embedding vectors to the Weaviate vector database.`);
}
