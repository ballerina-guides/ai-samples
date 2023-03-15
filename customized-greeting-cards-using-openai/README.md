# Generating and sending custom generated greetings with a design

This sample uses OpenAI GPT-3 to generate a greeting for a given occasion and DALL-E to generate a design. It then sends the greeting via email to a given address.

## Use case
Using this service, you can send emails with a custom generated greeting and card for special occasions.

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
6. In a separate browser window or tab, visit [OAuth 2.0 playground](https://developers.google.com/oauthplayground), select the required Gmail scopes, and then click **Authorize APIs**.
7. When you receive your authorization code, click **Exchange authorization code for tokens** to obtain the access token.

### Setting up OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create new secret key.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
gmailToken="<GMAIL_ACCESS_TOKEN>"
openAIToken="<OPENAI_API_KEY>"
```