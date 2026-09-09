import ballerina/http;
import ballerinax/ai.agent;
import ballerinax/azure.openai.chat;
import ballerinax/azure.openai.embeddings;
import ballerinax/pinecone.vector;

listener agent:Listener hrAgent = new (listenOn = check http:getDefaultListener());

service /agent on hrAgent {
    resource function post chat(@http:Payload agent:ChatReqMessage request) returns agent:ChatRespMessage|error {
        string query = request.message;
        embeddings:Deploymentid_embeddings_body embeddingsBody = {input: query};
        embeddings:Inline_response_200 embeddingsResult = check azureOpenAIEmbeddings->/deployments/[EMBEDDING_DEPLOYMENT_ID]/embeddings.post("2023-03-15-preview", embeddingsBody);

        float[] embeddingsFloat = decimalToFloatArray(embeddingsResult.data[0].embedding);
        vector:QueryRequest queryRequest = {
            topK: 4,
            includeMetadata: true,
            vector: embeddingsFloat
        };
        vector:QueryResponse response = check pinecodeVector->/query.post(queryRequest);
        vector:QueryMatch[] matches = check response.matches.ensureType();

        string context = check augment(matches);

        string systemPrompt = string `You are an HR Policy Assistant that provides employees with accurate answers
        based on company HR policies.Your responses must be clear and strictly based on the provided context.
        ${context}`;

        chat:CreateChatCompletionRequest chatRequest = {
            messages: [
                {role: "system", "content": systemPrompt},
                {role: "user", "content": query}
            ]
        };

        chat:CreateChatCompletionResponse chatResult =
        check azureOpenAIChat->/deployments/[LLM_DEPLOYMENT_ID]/chat/completions.post("2023-12-01-preview", chatRequest);
        ChatResponseChoice[] choices = check chatResult.choices.ensureType();
        string chatResponse = check choices[0].message?.content.ensureType();

        return {message: chatResponse};
    }
}
