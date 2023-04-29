# Question Answering based on Context using OpenAI GPT-3 and Pinecone 
This sample uses OpenAI GPT-3 and Pinecone to answer questions on a specific topic based on provided documents.

## Use case
Answers questions using OpenAI GPT-3 models and stored documentation in a Pinecone vector database. The contexts obtained from a Google sheet are initially added to the Pinecone vector database along with their embedding vectors to perform a similarity search at the runtime.

## Prerequisites
* Google account
* OpenAI account
* Pinecone account

### Setting up the Google account
1. Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard to create a new project.
2. Go to **Credentials -> OAuth consent screen**, enter a product name to be shown to users, and click **Save**.
3. On the **Credentials** tab, click **Create credentials** and select **OAuth client ID**.
4. Select an application type, enter a name for the application, and specify a redirect URI (enter https://developers.google.com/oauthplayground if you want to use
   [OAuth 2.0 playground](https://developers.google.com/oauthplayground) to receive the authorization code and obtain the
   access token).
5. Click **Create**. Your client ID and client secret appear.
6. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground), select the required Google Sheets scopes, and then click **Authorize APIs**.
7. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the access token.
8. Create a new Google Sheet in your account and add your document content as two columns **Heading** and **Content**.
9. Obtain the SheetID from the URL and Sheet Name.

### Setting up the OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create new secret key.

### Setting up the Pinecone account
1. Sign up and log in to [Pinecone](https://www.pinecone.io/).
2. Create a new project and specify an environment.
3. Click on `API Keys` and create an API key.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
sheetsAccessToken="<GOOGLE_SHEETS_ACCESS_TOKEN>"
sheetId="<GOOGLE_SHEET_ID>"
sheetName="<GOOGLE_SHEET_NAME>"
openAIToken="<OPENAI_API_KEY>"
pineconeKey = "<PINECONE_API_KEY>"
pineconeServiceUrl = "<PINECONE_SERVICE_URL>"
```
