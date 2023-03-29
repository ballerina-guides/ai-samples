# Tweet on upcoming and recently released movies using Azure OpenAI

## Use Case
Obtaines information on few upcoming and recently released movies from [TMDB](https://www.themoviedb.org/), generates a creative tweet using Azure OpenAI GPT3 models, and tweets it out.  

## Prerequisites
* Azure OpenAI service
* TMDB account
* Twitter developer account

## Setting up Azure OpenAI service
1. Follow the instructions given in [Azure Documentation](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/how-to/create-resource?pivots=web-portal) to create an Azure OpenAI resource and deploy a text completion model.
2. In the Azure Portal, go to **Keys and Endpoint** in the **Resource Management** section of the resource and obtain the service URL (**Endpoint**) and API key (either **KEY1** or **KEY2**).
3. Go to **Deployments** in the **Resource Management** section and obtain the name of the text completion model which was deployed in step 1.

## Setting up TMDB account
1. Sign up and log into [TMDB](https://www.themoviedb.org/login).
2. Click `Settings` and then click `API` tab in the left side bar.
3. Click `Create` or `click here` on the API page.

## Creating a Twitter developer account
Follow the instruction at https://developer.twitter.com/en/docs/twitter-api/getting-started/getting-access-to-the-twitter-api to create an account and obtain the required credentials.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
moviedbApiKey = "<TMDB_API_KEY>
openAIToken = "<AZURE_OPENAI_API_KEY>"
serviceUrl = "<AZURE_OPENAI_ENDPOINT>"
deploymentId = "<AZURE_MODEL_DEPLOYMENT_NAME>"
twitterApiKey = "<TWITTER_API_KEY>"
twitterApiSecret = "<TWITTER_API_KEY_SECRET>"
twitterAccessToken = "<TWITTER_ACCESS_TOKEN>"
twitterAccessTokenSecret = "<TWITTER_ACCESS_TOKEN_SECRET>"
```

## Run the program
Use `bal run` command to compile and run the Ballerina program. 
