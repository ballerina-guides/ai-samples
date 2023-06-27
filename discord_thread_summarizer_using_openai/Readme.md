# Summarize Forum Channel threads in Discord using OpenAI

## Use case
Read and summarize Discord Forum Channel threads that have had activity within the last 24 hours using OpenAI GPT 3.5-turbo model.

## Prerequisites
* OpenAI account
* Discord Bot with Read access to a Discord server
* Channel ID of the Discord Forum Channel

### Setting up OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create a new secret key.

### Setting up the Discord Bot
1. Follow the steps mentioned in Step 1 of the [Discord Developer Portal](https://discord.com/developers/docs/getting-started#step-1-creating-an-app) to create a new App and a Discord Bot with `Read Messages/View` Channels.
2. Make sure you copy the Bot token and keep it safe.
3. In the same page, scroll down and enable `MESSAGE CONTENT INTENT` in the Bot settings so that the Bot can read the message content.
4. Install the app to your Discord server so that the Bot can read the messages.
**Note:** The steps 1, 2, and 4 in this README are all mentioned in the [Discord Developer Portal](https://discord.com/developers/docs/getting-started#step-1-creating-an-app).

### Getting the Channel ID of the Discord Forum Channel
1. Follow the steps mentioned in [this article](https://support.discord.com/hc/en-us/articles/206346498-Where-can-I-find-my-User-Server-Message-ID-) to enable the Developer Mode in Discord.
2. Right click on the Discord Forum Channel and click on `Copy Channel ID` to copy the Channel ID.

## Configuration
Create a file called `Config.toml` at the root of the project and add the relevant configuration.

### Config.toml
```
openAIToken = "<OPENAI_API_KEY>"
forumChannelId = <DISCORD_FORUM_CHANNEL_ID>
botToken = "Bot <DISCORD_BOT_TOKEN>"
```

**Note:** The `forumChannelId` should be an integer and the `botToken` should be prefixed with `Bot ` as shown above.
