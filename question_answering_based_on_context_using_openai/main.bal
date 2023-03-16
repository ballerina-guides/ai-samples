import ballerina/http;
import ballerina/regex;
import ballerinax/googleapis.sheets;
import ballerinax/openai.embeddings;
import ballerinax/openai.text;

configurable string sheetsAccessToken = ?;
configurable string sheetId = ?;
configurable string sheetName = ?;
configurable string openAIToken = ?;

final sheets:Client gSheets = check new ({auth: {token: sheetsAccessToken}});
final text:Client openaiText = check new ({auth: {token: openAIToken}});
final embeddings:Client openaiEmbeddings = check new ({auth: {token: openAIToken}});

service / on new http:Listener(8080) {

    map<string> documents = {};
    map<decimal[]> docEmbeddings = {};

    function init() returns error? {
        sheets:Range range = check gSheets->getRange(sheetId, sheetName, "A2:B");

        //Populate the dictionaries with the content and embeddings for each doc.
        foreach any[] row in range.values {
            string title = <string>row[0];
            string content = <string>row[1];
            self.documents[title] = content;
            self.docEmbeddings[title] = check getEmbedding(title + "\n" + content);
        }
    }

    resource function get answer(string question) returns string?|error {
        string prompt = check constructPrompt(question, self.documents, self.docEmbeddings);
        text:CreateCompletionRequest prmt = {
            prompt: prompt,
            model: "text-davinci-003"
        };
        text:CreateCompletionResponse completionRes = check openaiText->/completions.post(prmt);
        return completionRes.choices[0].text;
    }
}

function getEmbedding(string text) returns decimal[]|error {
    embeddings:CreateEmbeddingRequest embeddingRequest = {
        input: text,
        model: "text-embedding-ada-002"
    };
    embeddings:CreateEmbeddingResponse embeddingRes = check openaiEmbeddings->/embeddings.post(embeddingRequest);
    return embeddingRes.data[0].embedding;
}

function countWords(string text) returns int => regex:split(text, " ").length();

function constructPrompt(string question, map<string> documents, map<decimal[]> docEmbeddings) returns string|error {
    [string, float?][] documentSimilarity = check getDocumentSimilarity(question, docEmbeddings);
    string context = "";
    int contextLen = 0;
    int maxLen = 1125; // approx equivalence between word and token count

    foreach [string, float?] item in documentSimilarity {
        string heading = item[0];
        string content = <string>documents[heading];

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

function cosineSimilarity(decimal[] vector1, decimal[] vector2) returns float {
    float dotProduct = 0.0;
    float magnitude1 = 0.0;
    float magnitude2 = 0.0;

    // Compute dot product and magnitudes
    foreach int i in 0 ..< vector1.length() {
        dotProduct += <float>vector1[i] * <float>vector2[i];
        magnitude1 += (<float>vector1[i]).pow(2);
        magnitude2 += (<float>vector2[i]).pow(2);
    }

    // Compute cosine similarity
    float magnitudeProduct = magnitude1.sqrt() * magnitude2.sqrt();
    if (magnitudeProduct == 0.0) {
        return 0.0;
    }
    return dotProduct / magnitudeProduct;
}

function getDocumentSimilarity(string question, map<decimal[]> docEmbeddings) returns [string, float?][]|error {
    // Get question embedding
    decimal[] questionEmbedding = check getEmbedding(question);

    [string, float?][] docSimilarity = [];

    foreach string heading in docEmbeddings.keys() {
        float similarity = cosineSimilarity(<decimal[]>docEmbeddings[heading], questionEmbedding);
        docSimilarity.push([heading, similarity]);
    }

    [string, float?][] docSimilaritySorted = from var item in docSimilarity
        order by item[1] descending
        select item;

    return docSimilaritySorted;
}

