import ballerina/io;
import ballerinax/openai;
import ballerina/lang.'float as langFloat;

configurable string openAIKey = ?;

function vectorNorm(float[] vector1, string norm = "l2") returns float|error {
    // Calculate l1 and l2 norm of a vector

    if norm == "l2" {
        float magnitude_squared = 0.0;
        foreach int i in 0 ..< vector1.length(){
            magnitude_squared += langFloat:pow(vector1[i], 2);
        }
        return langFloat:sqrt(magnitude_squared);
    }
    else if norm == "l1" {
        float absolute_magnitude = 0.0;
        foreach int i in 0 ..< vector1.length(){
            absolute_magnitude += langFloat:abs(vector1[i]);
        }
        return absolute_magnitude;
    }
    else {
        return error("The selected norm type is not implemented");
    }
}

function dotProduct(float[] vector1, float[] vector2) returns float|error {
    // Calculate dot product between two vectors

    if vector1.length() != vector2.length() {
        return error("Lengths of the two vectors should match for calculating the dot product");
    }
    else {
        float dot_product = 0.0;
        foreach int i in 0 ..< vector1.length(){
            dot_product += vector1[i] * vector2[i];
        }
        return dot_product;
    }
}

function cosineSimilarity(float[] vector1, float[] vector2) returns float|error {
    // Calculate cosine similarity between two vectors

    float vector1Norm = check vectorNorm(vector1, norm = "l2");
    float vector2Norm = check vectorNorm(vector2, norm = "l2");

    if vector1Norm == 0.0 || vector2Norm == 0.0 {
        return error("Cosine similarity is undefined for zero vectors");
    }
    else {
        return check dotProduct(vector1, vector2) / (vector1Norm * vector2Norm) ;
    }
}

public function main() returns error? {

    openai:OpenAIClient openaiClient = check new ({
        auth: {
            token: openAIKey
        }
    });

    string text1 = "What are you thinking?";
    string text2 = "What is on your mind?";

    openai:CreateEmbeddingRequest text1_embedding_request = {
        model: "text-embedding-ada-002",
        input: text1
    }; 

    openai:CreateEmbeddingRequest text2_embedding_request = {
        model: "text-embedding-ada-002",
        input: text2
    }; 

    openai:CreateEmbeddingResponse text1_embedding_response = check openaiClient->/embeddings.post(text1_embedding_request);
    openai:CreateEmbeddingResponse text2_embedding_response = check openaiClient->/embeddings.post(text2_embedding_request);

    float[] text1_embedding = text1_embedding_response.data[0].embedding;
    float[] text2_embedding = text2_embedding_response.data[0].embedding;

    float similarity = check cosineSimilarity(text1_embedding, text2_embedding);

    io:println("The similarity between the given two texts : ", similarity);

}
