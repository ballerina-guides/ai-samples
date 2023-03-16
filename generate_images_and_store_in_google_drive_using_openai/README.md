# Generate images using OpenAI based captions from a Google Sheet and store them in Google Drive 

## Use case
Generates images using OpenAI DALL-E by reading captions/descriptions given in a Google sheet and store the generated images in a Google Drive folder.

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
6. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground), select the required Google Drive/Sheets scopes, and then click **Authorize APIs**.
7. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the access token.
8. Create a new Google Sheet in your Google account and add captions/descriptions to generate images in column **A**.
9. Obtain the SheetID from the URL (https://docs.google.com/spreadsheets/d/**<GOOGLE_SHEET_ID>**/edit#gid=0) and Sheet Name.
10. Create a new folder in Google Drive and obtain the FolderID from the URL (https://drive.google.com/drive/folders/**<DRIVE_FOLDER_ID>**).

### Setting up OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create new secret key.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
googleAccessToken="<GOOGLE_SHEETS_ACCESS_TOKEN>"
openAIToken="<OPENAI_API_KEY>"
sheetId="<GOOGLE_SHEET_ID>"
sheetName="<GOOGLE_SHEET_NAME>"
gDriveFolderId="<DRIVE_FOLDER_ID>"
```