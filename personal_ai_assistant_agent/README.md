# Personal AI Assistant Agent  

This sample demonstrates the capabilities and ease of using Ballerina AI Agents.  

## Use Case  
The Ballerina Agent is equipped with capabilities/tools to:  
- Read email inbox  
- Send emails  
- Create calendar events  
- Read calendar events  

The agent can assist users in scheduling events, summarizing emails, and intelligently combining all tools to perform specific tasks.  

**Example:** 
*"Schedule a meeting with John based on the details in my latest email."*

The Ballerina AI agent will:  
1. Read the latest email from John.  
2. Extract date, time, and location.  
3. Create a calendar event.  
4. Send a confirmation email to John. 

## Prerequisites  
- Gmail account  
- Google Calendar  
- OpenAI account  

### Setting Up a Google Account  
1. Visit the [Google API Console](https://console.developers.google.com), click **Create Project**, and follow the wizard to create a new project.  
2. Go to **Credentials -> OAuth consent screen**, enter a product name to be shown to users, and click **Save**.  
3. On the **Credentials** tab, click **Create credentials** and select **OAuth client ID**.  
4. Select an application type, enter a name for the application, and specify a redirect URI (enter `https://developers.google.com/oauthplayground` if you want to use the [OAuth 2.0 Playground](https://developers.google.com/oauthplayground) to receive the authorization code and obtain the access token).  
5. Click **Create**. Your client ID and client secret will appear.  
6. In a separate browser window or tab, visit the [OAuth 2.0 Playground](https://developers.google.com/oauthplayground), select the required Gmail and Calendar scopes, and then click **Authorize APIs**.  
7. Once you receive your authorization code, click **Exchange authorization code for tokens** to obtain the access token.

### Setting Up an OpenAI Account  
1. Create an [OpenAI](https://platform.openai.com/) account.  
2. Go to **View API Keys** and create a new secret key.  

## Configuration  
Create a file called `Config.toml` at the root of the project.  

### `Config.toml`  
```toml
sheetsAccessToken = "<GOOGLE_SHEETS_ACCESS_TOKEN>"
sheetId = "<GOOGLE_SHEET_ID>"
sheetName = "<GOOGLE_SHEET_NAME>"

openAiApiKey = "<OPENAI_API_KEY>"

googleRefreshToken = "<GOOGLE_REFRESH_TOKEN>"
clientId = "<OAUTH2_CLIENT_ID>"
clientSecret = "<OAUTH2_CLIENT_SECRET>"
refreshUrl = "https://accounts.google.com/o/oauth2/token"

userName = "<YOUR_NAME>"
userEmail = "<YOUR_GMAIL_ADDRESS>"
```  
