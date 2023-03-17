# Covert audio text and summarize using OpenAI and tweet

 This sample fetches audio from the given URL and converts it to text. Then summarises the text and tweets it.

 ## Prerequisites
 * OpenAI account
 * Twitter developer account

 ### Setting up an OpenAI account
 1. Create an [OpenAI](https://platform.openai.com/) account.
 2. Go to **View API keys** and create a new secret key.

 ### Creating a Twitter developer account
 Follow the instruction at https://developer.twitter.com/en/docs/twitter-api/getting-started/getting-access-to-the-twitter-api to create an account and obtain the required credentials

 ## Configuration
 Create a file called `Config.toml` at the root of the project.

 ### Config.toml
 ```
 openAIToken="<OPENAI_API_KEY>"
 apiKey="<TWITTER_API_KEY>"
 apiSecret="<TWITTER_API_Key_Secret>"
 accessToken="<TWITTER_ACCESS_TOKEN>"
 accessTokenSecret="<TWITTER_ACCESS_TOKEN_SECRET>"
 ```

## Testing
Run the Ballerina project by executing `bal run` from the root.

```
bal run -- "https://cdn.simplecast.com/audio/404a3f47-e74f-4c91-beff-bf2977e22d22/episodes/5b5a2a5c-6334-4bcd-939c-8d25e96ff522/audio/3b66b225-9e44-4656-9cde-920e14c92220/default_tc.mp3?aid=rss_feed&feed=bKMTTEds"
```
