# Question Answering based on Context using OpenAI GPT-3  

This sample uses OpenAI GPT-3 to answer questions on a specific topic based on provided documents.

## Use case
Generate answers to questions in specific contexts. Using this service, you can add content/documentation relating to a specific topic into a Google sheet and get answers for questions relating to the content without having to go through all the relevant documents.

## Prerequisites
* Google account
* OpenAI account

### Setting up Google account
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

### Setting up OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create new secret key.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
sheetsAccessToken="<GOOGLE_SHEETS_ACCESS_TOKEN>"
sheetId="<GOOGLE_SHEET_ID>"
sheetName="<GOOGLE_SHEET_NAME>"
openAIToken="<OPENAI_API_KEY>"
```
