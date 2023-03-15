import ballerina/io;
import ballerina/math.vector as MathVector; 
import ballerinax/openai;

configurable string openAIToken = ?;

public function main() returns error? {

    final openai:OpenAIClient openaiClient = check new ({auth: {token: openAIToken}});

    string text1 = "What are you thinking?";
    string text2 = "What is on your mind?";

    openai:CreateEmbeddingRequest textEmbeddingRequest = {
        model: "text-embedding-ada-002",
        input: [text1, text2]
    }; 

    openai:CreateEmbeddingResponse textEmbeddingResponse = check openaiClient->/embeddings.post(textEmbeddingRequest);

    float[] text1Embedding = textEmbeddingResponse.data[0].embedding;
    float[] text2Embedding = textEmbeddingResponse.data[1].embedding;

    float similarity = check MathVector:cosineSimilarity(text1Embedding, text2Embedding);

    io:println("The similarity between the given two texts : ", similarity);

}
