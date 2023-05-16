import ballerina/http;
import ballerina/io;
import ballerina/regex;
import ballerinax/googleapis.sheets;
import ballerinax/openai.embeddings;
import ballerinax/openai.chat;
import ballerinax/pinecone.vector as pinecone;

configurable string sheetsAccessToken = ?;
configurable string sheetId = ?;
configurable string sheetName = ?;
configurable string openAIToken = ?;
configurable string pineconeKey = ?;
configurable string pineconeServiceUrl = ?;

final sheets:Client gSheets = check new ({auth: {token: sheetsAccessToken}});
final chat:Client openAIChat = check new ({auth: {token: openAIToken}});
final embeddings:Client openaiEmbeddings = check new ({auth: {token: openAIToken}});
final pinecone:Client pineconeClient = check new ({apiKey: pineconeKey}, serviceUrl = pineconeServiceUrl);

const MAXIMUM_NO_OF_DOCS = 10;
const NAMESPACE = "ChoreoDocs";

enum Role {
    SYSTEM = "system",
    USER = "user",
    ASSISTANT = "assistant"
}

service / on new http:Listener(8080) {
    function init() returns error? {
        sheets:Range range = check gSheets->getRange(sheetId, sheetName, "A2:B");
        pinecone:Vector[] vectors = [];

        foreach any[] row in range.values {
            string title = <string>row[0];
            string content = <string>row[1];
            float[] vector = check getEmbedding(string `${title} ${"\n"} ${content}`);
            vectors[vectors.length()] = {id: title, values: vector, metadata: {"content": content}};
        }

        pinecone:UpsertResponse response = check pineconeClient->/vectors/upsert.post({vectors, namespace: NAMESPACE});
        if response.upsertedCount != range.values.length() {
            return error("Failed to insert embedding vectors to pinecone.");
        }
        io:println("Successfully inserted embedding vectors to pinecone.");
    }

    resource function get answer(string question) returns string?|error {
        chat:ChatCompletionRequestMessage[] messages = [
            {
                role: SYSTEM,
                content: "Answer the question as truthfully as possible using the provided context, and if the answer is not " +
                "contained within the text below, say \"I don't know.\""
            }
        ];

        string prompt = check constructPrompt(question);
        messages.push({role: USER, content: prompt});

        chat:CreateChatCompletionRequest chatReq = {
            messages,
            model: "gpt-3.5-turbo",
            max_tokens: 2000
        };
        chat:CreateChatCompletionResponse chatRes = check openAIChat->/chat/completions.post(chatReq);
        return chatRes.choices[0].message?.content;
    }
}

function getEmbedding(string text) returns float[]|error {
    embeddings:CreateEmbeddingRequest embeddingRequest = {
        input: text,
        model: "text-embedding-ada-002"
    };
    embeddings:CreateEmbeddingResponse embeddingRes = check openaiEmbeddings->/embeddings.post(embeddingRequest);
    return embeddingRes.data[0].embedding;
}

function countWords(string text) returns int => regex:split(text, " ").length();

function constructPrompt(string question) returns string|error {
    float[] questionEmbedding = check getEmbedding(question);

    pinecone:QueryRequest req = {
        namespace: NAMESPACE,
        topK: MAXIMUM_NO_OF_DOCS,
        vector: questionEmbedding,
        includeMetadata: true
    };
    pinecone:QueryResponse res = check pineconeClient->/query.post(req);
    pinecone:QueryMatch[]? rows = res.matches;

    string context = "";
    int contextLen = 0;
    int maxLen = 1125; // approx equivalence between word and token count

    if rows is () {
        return error("No documents found for the given query.");
    }
    foreach pinecone:QueryMatch row in rows {
        pinecone:VectorMetadata? rowMetadata = row.metadata;
        if rowMetadata is () {
            return error("No metadata found for the given document.");
        }
        string content = check rowMetadata["content"].ensureType();
        contextLen += countWords(content);
        if contextLen > maxLen {
            break;
        }
        context += "\n*" + content;
    }

    string instruction = "Answer the question as truthfully as possible using the provided context," +
    " and if the answer is not contained within the text below, say \"I don't know.\"\n\n";
    return string `${instruction}Context:${"\n"} ${context} ${"\n\n"} Q: ${question} ${"\n"} A:`;
}
