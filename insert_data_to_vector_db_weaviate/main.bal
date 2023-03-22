import ballerina/io;
import ballerinax/weaviate;
import ballerinax/openai.embeddings;
import ballerinax/googleapis.sheets;

configurable string openAIToken = ?;
configurable string weaviateToken = ?;
configurable string weaviateURL = ?;

configurable string sheetAccessToken = ?;
configurable string sheetId = ?;
configurable string sheetName = ?;

const string RANGE = "A:C";

final embeddings:Client openaiClient = check new ({auth: {token: openAIToken}});
final weaviate:Client weaviateClient = check new ({auth: {token: weaviateToken}}, weaviateURL);
final sheets:Client gsheets = check new ({auth: {token: sheetAccessToken}});

public function main() returns error? {

    sheets:Range range = check gsheets->getRange(sheetId, sheetName, RANGE);

    string className = "QuestionAnswerStore";
    string[] textArr = [];
    weaviate:Object[] documentObjectArray = [];

    // Iterates through the stream and extract the content
    int j = 0;
    foreach var row in range.values {
        if (row.length() == 3){
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
        j = j+1;
        if (j > 10){
            break;
        }
    }

    embeddings:CreateEmbeddingResponse embeddingResponse = check openaiClient->/embeddings.post({
            model: "text-embedding-ada-002",
            input: textArr
        }
    );

    // insert embedding vectors to the weaviate objects
    foreach int i in 0 ... embeddingResponse.data.length() - 1 {
        documentObjectArray[i].vector = embeddingResponse.data[i].embedding;
    }

    weaviate:Batch_objects_body batch = {
        objects: documentObjectArray
    };

    weaviate:ObjectsGetResponse[] responseArray = check weaviateClient->/batch/objects.post(batch);

    foreach var res in responseArray {
        io:println(res);
    }
}
