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
