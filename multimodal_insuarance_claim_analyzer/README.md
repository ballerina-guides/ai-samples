# AI-Powered Insurance Claim Processing

This project demonstrates how to build an AI-powered service in Ballerina that processes insurance claims. The service exposes an HTTP endpoint that accepts multipart form data containing a text description and an image of the claim.

It utilizes the `ballerina/ai` module to send this multimodal input (text and image) to a Large Language Model (LLM), which then analyzes the content and returns a concise summary. This example highlights the ease of integrating generative AI capabilities into a Ballerina network service.

-----

## Prerequisites

1.  Install a recent version of Ballerina. You can download it from [here](https://ballerina.io/downloads/).
2.  Install the **Ballerina extension** for Visual Studio Code.

-----

## Running the Project

You can run this project in two ways: by using the default model provider facilitated by WSO2 Copilot for a quick start, or by configuring your own LLM provider with your API keys for development and production scenarios.

### **Option 1: Use the Default Model (Quick Start)**

This approach allows you to run the example without needing your own LLM API keys, making it ideal for quick trials.

#### 1\. Log in to WSO2 Copilot

  - Log in to your WSO2 Copilot account from within VS Code.

#### 2\. Configure the Default Model Provider

  - In VS Code, press `Ctrl + Shift + P` (or `Cmd + Shift + P` on macOS) to open the command palette.
  - Search for and select the **"Ballerina: Configure default WSO2 model provider"** command.
  - Your configuration will be automatically generated and added to a `Config.toml` file in your project directory.

#### 3\. Run the Service

  - Open a terminal within your project directory.

  - Execute the following command to start the service:

    ```bash
    $ bal run
    ```

-----

### **Option 2: Use Your Own LLM Keys**

You can use your own LLM keys with a model provider from the relevant `ballerinax/ai.<provider>` package (e.g., `ballerinax/ai.openai`, `ballerinax/ai.azure`, etc.).

For example, you can use an Open AI model as follows.

#### 1\. Modify the Code

Update your `.bal` file to import the specific provider and initialize it with your API key.

```ballerina
import ballerina/ai;
import ballerina/http;
import ballerina/mime;
import ballerinax/ai.openai; // Import the specific provider

// --- Types and Enums remain the same ---
enum submissionStatus {
    SUCCESS,
    FAILED
}
type ClaimResponse record {|
    submissionStatus submissionStatus;
    string summary?;
|};

// Configure the API key
configurable string apiKey = ?;

// Initialize the specific model provider
final ai:ModelProvider modelProvider = check new openai:ModelProvider(apiKey, openai:GPT_4O);

# Claims Processing API Service
service /insurance on new http:Listener(8080) {

    resource function post claims(http:Request request) returns ClaimResponse|error {
        mime:Entity[] bodyParts = check request.getBodyParts();

        string description = check bodyParts[0].getText();
        byte[] claimImage = check bodyParts[1].getByteArray();
        ai:ImageDocument claimImageDocument = {
            content: claimImage
        };

        // Use the initialized provider to generate the summary
        string summary = check modelProvider->generate(
            `Please summarize the following claim
                - Description: ${description}
                - Image of the claim: ${claimImageDocument}`);
        return {
            submissionStatus: SUCCESS,
            summary
        };
    }
}
```

#### 2\. Configure Your API Key

Create a `Config.toml` file in your project's root directory and add your API key.

```toml
# Config.toml
apiKey="<YOUR_OPENAI_API_KEY>"
```

#### 3\. Run the Service

  - Open a terminal in the project directory.

  - Run the following command:

    ```bash
    $ bal run
    ```

The service will start on `http://localhost:8080`.

-----

## Testing the Service

You can test the service by sending a `multipart/form-data` request using a tool like cURL.

### Sample Request

```bash
curl -X POST http://localhost:8080/insurance/claims \
-F "description=Claim for a cracked phone screen." \
-F "image=@./resources/cracked_phone.jpeg"
```

### Sample Response

A successful request will receive a JSON response containing the submission status and the AI-generated summary, similar to the one below:

```json
{
    "submissionStatus": "SUCCESS",
    "summary": "The user has submitted a claim for a cracked phone screen. The provided image confirms a significant crack across the front display of a smartphone."
}
```
