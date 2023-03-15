import ballerina/http;
import ballerina/log;
import ballerina/regex;
import ballerinax/googleapis.sheets;
import ballerinax/openai;

// Google Sheets API client configuration parameters
configurable string sheetsAccessToken = ?;
configurable string sheetId = ?;
configurable string sheetName = ?;

// OpenAI token
configurable string openAIToken = ?;

type Request record {|
    string question;
|};

type Response record {|
    string answer;
|};

// Configure Google Sheets client
final sheets:Client spreadsheetClient = check new ({auth: {token: sheetsAccessToken}});

// Configure OpenAI client
final openai:OpenAIClient openaiClient = check new ({auth: {token: openAIToken}});

function countWords(string text) returns int {
    string[] words = regex:split(text, " ");
    return words.length();
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

function getEmbedding(string text) returns decimal[]|error {
    openai:CreateEmbeddingRequest input = {
        input: text,
        model: "text-embedding-ada-002"
    };
    openai:CreateEmbeddingResponse embeddingRes = check openaiClient->/embeddings.post(input);
    return embeddingRes.data[0].embedding;
}

function getDocumentSimilarity(string question, map<decimal[]> doc_embeddings) returns [string, float?][]|error {
    // Get question embedding
    decimal[] question_embedding = check getEmbedding(question);

    [string, float?][] doc_similarity = [];

    foreach string heading in doc_embeddings.keys() {
        float similarity = cosineSimilarity(<decimal[]>doc_embeddings[heading], question_embedding);
        doc_similarity.push([heading, similarity]);
    }

    [string, float?][] doc_similarity_sorted = from var item in doc_similarity
        order by item[1] descending
        select item;

    return doc_similarity_sorted;
}

function constructPrompt(string question, map<string> documents, map<decimal[]> doc_embeddings) returns string|error {
    [string, float?][] document_similarity = check getDocumentSimilarity(question, doc_embeddings);
    string context = "";
    int contextLen = 0;
    int maxLen = 1125; // approx equivalence between word and token count

    foreach [string, float?] item in document_similarity {
        string heading = item[0];
        string content = <string>documents[heading];

        contextLen += countWords(content);
        if contextLen > maxLen {
            break;
        }

        context += "\n*" + content;
    }

    string instruction = "Answer the question as truthfully as possible using the provided context, and if the answer is not contained within the text below, say \"I don't know.\"\n\nContext:\n";
    return string `${instruction} ${context} \n\n Q: ${question} \n A:`;
}

function generateAnswer(string prompt) returns string|error {
    openai:CreateCompletionRequest prmt = {
        prompt: prompt,
        model: "text-davinci-003"
    };
    openai:CreateCompletionResponse completionRes = check openaiClient->/completions.post(prmt);
    return completionRes.choices[0].text ?: "";
}

function loadData(string sheetId, string sheetName = "Sheet1") returns [map<string>, map<decimal[]>]|error {
    // Fetch the data from the 'heading' and 'content' columns.
    sheets:Range range = check spreadsheetClient->getRange(sheetId, sheetName, "A2:B");

    // Define an empty dictionaries for documents and embeddings.
    map<string> documents = {};
    map<decimal[]> doc_embeddings = {};

    // Iterate through the array of arrays and populate the dictionaries with the content and embeddings for each doc.
    foreach any[] row in range.values {
        string title = <string>row[0];
        string content = <string>row[1];

        documents[title] = content;
        doc_embeddings[title] = check getEmbedding(title + "\n" + content);
    }
    return [documents, doc_embeddings];
}

// Load the data and compute the embeddings when the service starts
[map<string>, map<decimal[]>] [documents, doc_embeddings] = check loadData(sheetId, sheetName);

service / on new http:Listener(8080) {

    resource function post generateAnswer(@http:Payload Request request) returns Response {

        string question = request.question;
        string|error prompt = constructPrompt(question, documents, doc_embeddings);
        if prompt is error {
            log:printError("Error constructing prompt: ", prompt);
            return {answer: ""};
        }

        string|error answer = generateAnswer(prompt);
        if answer is error {
            log:printError("Error generating answer: ", answer);
            return {answer: ""};
        }

        return {answer: answer};
    }
}
