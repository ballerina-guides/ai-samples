# Insert a batch of data to Weaviate vector search engine from a Google Sheet

## Use case
Obtain embedding vectors for a batch of data retrieved from a Google sheet using OpenAI GPT3 models and insert them to Weaviate vector database.

## Prerequisites
* Google account
* OpenAI account
* Weaviate Deployment

### Setting up Google account
1. Visit [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard to create a new project.
2. Go to **OAuth consent screen**, enter a product name to be shown to users, and click **Save**.
3. On the **Credentials** tab, click **Create credentials** and select **OAuth client ID**.
4. Select an application type, enter a name for the application, and specify a redirect URI (enter https://developers.google.com/oauthplayground if you want to use
   [OAuth 2.0 playground](https://developers.google.com/oauthplayground) to receive the authorization code and obtain the
   access token).
5. Click **Create**. Your client ID and client secret appear.
6. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground), select the required Google Sheets scopes, and then click **Authorize APIs**.
7. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the access token.
8. Create a new Google sheet in your Google account and import `data/data.csv` to the sheet from columns **A:C**.
9. Obtain the Sheet ID from the URL (https://docs.google.com/spreadsheets/d/**<GOOGLE_SHEET_ID>**/edit#gid=0) and Sheet Name.

### Setting up OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create new secret key.

### Setting up Weaviate Sandbox
1. Create an [Weaviate Cloud Services (WCS)](https://console.weaviate.io/) account.
2. Create a new Weaviate Cluster (in Sandbox Tier).
2. Go to **WSC Module** and retrieve the cluster URL and the API key.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
openAIToken = "<OPENAI_API_KEY>"
weaviateURL = "<WEAVIATE_CLUSTER_URL>"
weaviateToken = "<WEAVIATE_API_KEY>"
sheetAccessToken = "<GOOGLE_SHEETS_ACCESS_TOKEN>"
sheetId = "<GOOGLE_SHEET_ID>"
sheetName = "<GOOGLE_SHEET_NAME>"
```