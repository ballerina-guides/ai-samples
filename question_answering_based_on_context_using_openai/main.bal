import ballerina/http;
import ballerina/math.vector;
import ballerina/regex;
import ballerinax/googleapis.sheets;
import ballerinax/openai.embeddings;
import ballerinax/openai.chat;

configurable string sheetsAccessToken = ?;
configurable string sheetId = ?;
configurable string sheetName = ?;
configurable string openAIToken = ?;

final sheets:Client gSheets = check new ({auth: {token: sheetsAccessToken}});
final chat:Client openAIChat = check new({auth: {token:openAIToken}});
final embeddings:Client openaiEmbeddings = check new ({auth: {token: openAIToken}});

service / on new http:Listener(8080) {

    map<string> documents = {};
    map<float[]> docEmbeddings = {};

    function init() returns error? {
        sheets:Range range = check gSheets->getRange(sheetId, sheetName, "A2:B");

        //Populate the dictionaries with the content and embeddings for each doc.
        foreach any[] row in range.values {
            string title = <string>row[0];
            string content = <string>row[1];
            self.documents[title] = content;
            self.docEmbeddings[title] = check getEmbedding(string `${title} ${"\n"} ${content}`);
        }
    }

    resource function get answer(string question) returns string?|error {
        string prompt = check constructPrompt(question, self.documents, self.docEmbeddings);

            chat:CreateChatCompletionRequest request = {
            model: "gpt-4o-mini",
            messages: [{
                "role": "user",
                "content": prompt
                }]
        };

        chat:CreateChatCompletionResponse response = check openAIChat->/chat/completions.post(request);
        return response.choices[0].message.content;
       
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

function constructPrompt(string question, map<string> documents, map<float[]> docEmbeddings) returns string|error {
    string[] documentSimilarity = check getDocumentSimilarity(question, docEmbeddings);
    string context = "";
    int contextLen = 0;
    int maxLen = 1125; // approx equivalence between word and token count

    foreach string heading in documentSimilarity {
        string content = documents[heading] ?: "";

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

function getDocumentSimilarity(string question, map<float[]> docEmbeddings) returns string[]|error {
    // Get question embedding
    float[] questionEmbedding = check getEmbedding(question);

    map<float> docSimilarity = {};
    foreach string heading in docEmbeddings.keys() {
        float similarity = vector:cosineSimilarity(docEmbeddings[heading] ?: [], questionEmbedding);
        docSimilarity[heading] = similarity;
    }
    //Order the headings by similarity
    return from string heading in docSimilarity.keys()
        order by docSimilarity[heading] descending
        select heading;
}
