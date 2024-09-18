import ballerina/io;
import ballerina/math.vector;
import ballerinax/openai.embeddings;

configurable string openAIToken = ?;

public function main() returns error? {
    final embeddings:Client embeddingsClient = check new ({auth: {token: openAIToken}});

    string text1 = "What are you thinking?";
    string text2 = "you are playing cricket";
    embeddings:CreateEmbeddingRequest embeddingReq = {
        model: "text-embedding-3-small",
        input: [text1, text2]
    };
    embeddings:CreateEmbeddingResponse embeddingRes = check embeddingsClient->/embeddings.post(embeddingReq);

    float[] text1Embedding = embeddingRes.data[0].embedding;
    float[] text2Embedding = embeddingRes.data[1].embedding;
    float similarity = vector:cosineSimilarity(text1Embedding, text2Embedding);
    io:println("The similarity between the given two texts : ", similarity);
}