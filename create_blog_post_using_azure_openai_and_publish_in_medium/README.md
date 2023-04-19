# Generate a blog article using Azure OpenAI and publish on Medium

## Use Case
Generates content in markdown format for a blog article for a given topic using a text completion model from Azure OpenAI and publishes the content as a blog post on Medium.

## Prerequisites
* Azure OpenAI service
* Medium account

## Setting up Azure OpenAI service
1. Follow the instructions given in [Azure Documentation](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/how-to/create-resource?pivots=web-portal) to create an Azure OpenAI resource and deploy a text completion model.
2. In the Azure Portal, go to **Keys and Endpoint** in the **Resource Management** section of the resource and obtain the service URL (**Endpoint**) and API key (either **KEY1** or **KEY2**).
3. Go to **Deployments** in the **Resource Management** section and obtain the name of the text completion model which was deployed in step 1.

## Setting up Medium account
1. Sign up and log into [Medium](https://medium.com/).
2. Go to the profile [**Settings**](https://medium.com/me/settings) -> **Security and apps**.
3. Click **Integration tokens**, insert a description and generate a token to access Medium via the API.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
openAIToken="<AZURE_OPENAI_API_KEY>"
serviceUrl="<AZURE_OPENAI_ENDPOINT>"
deploymentId="<AZURE_MODEL_DEPLOYMENT_NAME>"
mediumToken="<MEDIUM_TOKEN>"
```

## Run the program
Run the Ballerina project by executing `bal run` from the root by passing the desired topic for the blog post as a parameter.

`bal run -- "Ballerina Language"`
