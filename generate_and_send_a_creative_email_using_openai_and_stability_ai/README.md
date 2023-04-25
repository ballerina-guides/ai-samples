# Generate a poem and an image on a topic using OpenAI and Stable Diffusion and email both of them

## Use case
Generates a poem about a topic using OpenAI and an image about the same topic using Stable Diffusion and email both of them to a given mail address.

## Prerequisites
* Google account
* OpenAI account
* Stability AI account

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

### Setting up Stability AI account
- Create a [Stability AI](https://beta.dreamstudio.ai/generate/) account.
- Obtain the API key by referring to [Stability AI Authentication](https://platform.stability.ai/docs/getting-started/authentication/).

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
gmailToken = "<GMAIL_ACCESS_TOKEN>"
openAIToken = "<OPENAI_API_KEY>"
stabilityAIKey = "<STABILITY_AI_API_KEY>"
recipientEmail = "<RECIPIENT_EMAIL_ADDRESS>"
```