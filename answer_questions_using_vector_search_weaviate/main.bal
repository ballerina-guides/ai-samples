import ballerina/http;
import ballerinax/weaviate;
import ballerinax/openai.embeddings;

configurable string openAIToken = ?;
configurable string weaviateToken = ?;
configurable string weaviateURL = ?;

const CLASS_NAME = "QuestionAnswerStore";

final embeddings:Client openaiClient = check new ({auth: {token: openAIToken}});
final weaviate:Client weaviateClient = check new({auth: {token: weaviateToken}}, weaviateURL);

service / on new http:Listener(8080) {
    
    resource function get answer(string question) returns error|record {|weaviate:JsonObject...;|}? {

        // retrieve open-ai ada embeddings for the query
        embeddings:CreateEmbeddingResponse embeddingResponse = check openaiClient->/embeddings.post({
                model: "text-embedding-ada-002",
                input: question
            }
        );

    
        float[] vector = embeddingResponse.data[0].embedding;
        
        string graphQLQuery =  string`{
                                    Get {
                                        ${CLASS_NAME} (
                                        nearVector: {
                                            vector: ${vector.toString()}
                                            }
                                            limit: 1
                                        ){
                                        question
                                        answer
                                        _additional {
                                            certainty,
                                            id
                                            }
                                        }
                                    }
                                }`;

        weaviate:GraphQLResponse|error results = check weaviateClient->/graphql.post({
            query: graphQLQuery
        });
    
        if (results is weaviate:GraphQLResponse){
            return results.data;
        } else {
            return results;
        }
    }
}