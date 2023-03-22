# Answer questions using similarity search of Weaviate Vector Search Engine

## Use case
Ask questions from knowledge stored in Weaviate Vector Search Engine using the embedding similarity search. Embedding vectors are retreived using the GPT3 models from OpenAI. 

## Prerequisites
* OpenAI account
* Weaviate Deployment

### Setting up OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create new secret key.

### Setting up Weaviate Sandbox
1. Create an [Weaviate Cloud Services (WCS)](https://console.weaviate.io/) account.
2. Create a new Weaviate Cluster (in Sandbox Tier).
2. Go to **WSC Module** and retrieve the cluster URL and the API key.
3. Populate the data using the sample [Insert a batch of data to Weaviate vector search engine from a Google Sheet](../insert_data_to_vector_db_weaviate/README.md)

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
openAIToken = "<OPENAI_API_KEY>"
weaviateURL = "<WEAVIATE_CLUSTER_URL>"
weaviateToken = "<WEAVIATE_API_KEY>"
```