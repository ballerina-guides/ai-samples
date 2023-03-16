# Correcting grammar and spellings in text using OpenAI

This sample reads content from a file and uses OpenAI GPT-3 edits model to correct its grammar and spelling mistakes.

## Prerequisites
* OpenAI account

### Setting up OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create new secret key.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
openAIToken="<OPENAI_API_KEY>"
```