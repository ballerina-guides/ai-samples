# Fine tune OpenAI models

This sample uploads a training data jsonl file to OpenAI and submits a fine tune job.

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
