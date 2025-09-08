# AI-Powered Insurance Claim Validation

This project demonstrates how to build an AI-powered service in Ballerina that validates insurance claims. The service exposes an HTTP endpoint that accepts multipart form data containing a text description and an image of the claim.

It utilizes the `ballerina/ai` module to send this multimodal input (text and image) to a Large Language Model (LLM). The AI's role is to act as a validator, cross-checking the user's description against the visual evidence in the image. Based on the AI's response, the claim is either accepted or rejected, showcasing a realistic, practical use case for generative AI in a business process.

## Prerequisites

1. Install a recent version of Ballerina. You can download it from [here](https://ballerina.io/downloads/).
2. Install the **Ballerina extension** for Visual Studio Code.

---

## Running the Project

You can run this project in two ways: by using the default model provider facilitated by WSO2 Copilot for a quick start, or by configuring your own LLM provider with your API keys for development and production scenarios.

### **Option 1: Use the Default Model (Quick Start)**

This approach allows you to run the example without needing your own LLM API keys, making it ideal for quick trials.

#### 1. Log in to WSO2 Copilot

- Log in to your WSO2 Copilot account from within VS Code.

#### 2. Configure the Default Model Provider

- In VS Code, press `Ctrl + Shift + P` (or `Cmd + Shift + P` on macOS) to open the command palette.
- Search for and select the **"Ballerina: Configure default WSO2 model provider"** command.
- Your configuration will be automatically generated and added to a `Config.toml` file in your project directory.

#### 3. Run the Service

- Open a terminal within your project directory.
- Execute the following command to start the service:

    ```bash
    $ bal run
    ```

---

### **Option 2: Use Your Own LLM Keys**

You can use your own LLM keys with a model provider from the relevant `ballerinax/ai.<provider>` package (e.g., `ballerinax/ai.openai`, `ballerinax/ai.azure`, etc.).

For example, you can use an OpenAI model as follows.

#### 1. Modify the Code

Update your `.bal` file to import the specific provider and initialize it with your API key.

```ballerina
import ballerina/ai;
import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/uuid;
import ballerinax/ai.openai; // Import the specific provider

// --- Types and Enums remain the same ---
enum Status {
    ACCEPTED,
    REJECTED
}
// ... (rest of the types)

// Configure the API key
configurable string apiKey = ?;

// Initialize the specific model provider
final ai:ModelProvider modelProvider = check new openai:ModelProvider(apiKey, openai:GPT_4O);

# Claims Processing API Service
service /insurance on new http:Listener(8080) {
    // ... (resource function remains the same)
}
````

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

You can test the service by sending a `multipart/form-data` request using a tool like cURL. The AI will validate if the image matches the description.

### Sample Request

```bash
curl -X POST http://localhost:8080/insurance/claims \
-F "description=Claim for a cracked phone screen." \
-F "image=@./resources/cracked_phone.jpeg"
```

### Sample Responses

A successful request will receive a JSON response indicating whether the claim was `ACCEPTED` or `REJECTED` based on the AI's validation.

#### **Example of an ACCEPTED Claim**

If the description and image are consistent:

```json
{
    "claimId": "9a5a8b5e-0b0a-4a7e-9c8a-3e2c1b8d6f5e",
    "status": "ACCEPTED",
    "reason": "The image clearly shows a cracked phone screen, which is consistent with the user's description."
}
```
