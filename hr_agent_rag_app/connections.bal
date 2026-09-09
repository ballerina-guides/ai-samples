import ballerinax/azure.openai.chat;
import ballerinax/azure.openai.embeddings;
import ballerinax/pinecone.vector;

final embeddings:Client azureOpenAIEmbeddings = check new (
    config = {auth: {apiKey: AZURE_API_KEY}},
    serviceUrl = AZURE_SERVICE_URL
);

final vector:Client pinecodeVector = check new ({
    apiKey: PINECONE_API_KEY
}, serviceUrl = PINECONE_URL);

final chat:Client azureOpenAIChat = check new (
    config = {auth: {apiKey: AZURE_API_KEY}},
    serviceUrl = AZURE_SERVICE_URL
);
