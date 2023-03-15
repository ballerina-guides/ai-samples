import ballerina/io;
import ballerinax/openai;
import ballerina/math.vector as MathVector; 

configurable string openAIKey = ?;

public function main() returns error? {

    openai:OpenAIClient openaiClient = check new ({
        auth: {
            token: openAIKey
        }
    });

    string text1 = "What are you thinking?";
    string text2 = "What is on your mind?";

    openai:CreateEmbeddingRequest text_embedding_request = {
        model: "text-embedding-ada-002",
        input: [text1, text2]
    }; 

    openai:CreateEmbeddingResponse text_embedding_response = check openaiClient->/embeddings.post(text_embedding_request);

    float[] text1_embedding = text_embedding_response.data[0].embedding;
    float[] text2_embedding = text_embedding_response.data[1].embedding;

    float similarity = check MathVector:cosineSimilarity(text1_embedding, text2_embedding);

    io:println("The similarity between the given two texts : ", similarity);

}
