# Chatbot service for Slack using Azure OpenAI

## Use Case
The service responds to questions asked in Slack chanels using the slash command (`/<COMMAND> question`), using the Azure OpenAI chat model by maintainging a history of 25 messages.

## Prerequisites
* Azure OpenAI service
* Slack account and app

## Setting up Azure OpenAI service
1. Follow the instructions given in [Azure Documentation](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/how-to/create-resource?pivots=web-portal) to create an Azure OpenAI resource and deploy a text completion model.
2. In the Azure Portal, go to **Keys and Endpoint** in the **Resource Management** section of the resource and obtain the service URL (**Endpoint**) and API key (either **KEY1** or **KEY2**).
3. Go to **Deployments** in the **Resource Management** section and obtain the name of the text completion model which was deployed in step 1.

## Setting up Slack account and app
1. Sign up or sign in to [Slack](https://slack.com/get-started#/createnew).
2. Create a new [Slack app](https://api.slack.com/apps).
3. Configure a new slash command (e.g. `/test`) for the app via **Features &rarr; Slash Commands**
    * To obtain the **Request URL** for the slash command, run the Ballerina service locally and get the forwarding URL by running [ngrok](https://ngrok.com/download) on the same port using the command `ngrok http <PORT>`. The **Request URL** will be `<ngrok_url>/slack/events`. 
4. Save the changes and install the app to the workspace via **Settings &rarr; Install App**.
5. Obtain the **Signing Secret** for request verification from **Settings &rarr; Basic Information &rarr; App Credentials**.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
openAIToken="<AZURE_OPENAI_API_KEY>"
serviceUrl="<AZURE_OPENAI_ENDPOINT>"
deploymentId="<AZURE_MODEL_DEPLOYMENT_NAME>"
slackSigningSecret=<SLACK_SIGNING_SECRET>
```

## Run and consume the service
1. Run the Ballerina service by executing `bal run` from the root.
2. Go to the one of the chanels in the Slack workspace where the APP was installed and send a message using the configured slash command (e.g. `\test Hi`).
    * If the **Request URL** previously obtained from ngrok is expired, obtain a new one and update the slash command congiguration.
    * Make sure that the requests are being forwarded to the localhost port by ngrok.