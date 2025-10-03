# AI-Powered Insurance Claim Validation

This project demonstrates how to build an AI-powered service in Ballerina that validates insurance claims. The service exposes an HTTP endpoint that accepts multipart form data containing a text description and an image of the claim.

It utilizes the `ballerina/ai` module to send this multimodal input (text and image) to a large language model (LLM) to validate the description, cross-checking the user's description against the visual evidence in the image. Based on the response, the claim is either accepted or rejected.

## Prerequisites

1. Install a recent version of Ballerina. You can download it from [here](https://ballerina.io/downloads/).
2. Install the **Ballerina extension** for Visual Studio Code.

---

## Running the project

You can run this project in two ways: by using the default model provider facilitated by WSO2 Copilot for a quick start, or by configuring your own LLM provider with your API keys for development and production scenarios.

### **Option 1: Use the Default Model (Quick Start)**

This approach allows you to run the example without needing your own LLM API keys, making it ideal for quick trials.

#### 1. Log in to WSO2 copilot

- Log in to your WSO2 Copilot account from within VS Code.

#### 2. Configure the default model provider

- In VS Code, press `Ctrl + Shift + P` (or `Cmd + Shift + P` on macOS) to open the command palette.
- Search for and select the **"Ballerina: Configure default WSO2 model provider"** command.
- Your configuration will be automatically generated and added to a `Config.toml` file in your project directory.

#### 3. Run the service

- Open a terminal within your project directory.
- Execute the following command to start the service:

    ```bash
    $ bal run
    ```

---

### **Option 2: Use your own LLM keys**

You can use your own LLM keys with a model provider from the relevant `ballerinax/ai.<provider>` package (e.g., `ballerinax/ai.openai`, `ballerinax/ai.azure`, etc.).

For example, you can use an OpenAI model as follows.

#### 1. Modify the code

Update your `.bal` file to import the specific provider and initialize it with your API key.

```ballerina
import ballerinax/ai.openai; // Import the specific provider

// Configure the API key
configurable string apiKey = ?;

// Initialize the specific model provider
final ai:ModelProvider modelProvider = check new openai:ModelProvider(apiKey, openai:GPT_4O);
````

#### 2\. Configure your API key

Create a `Config.toml` file in your project's root directory and add your API key.

```toml
# Config.toml
apiKey="<YOUR_OPENAI_API_KEY>"
```

#### 3\. Run the service

  - Open a terminal in the project directory.
  - Run the following command:
    ```bash
    $ bal run
    ```

The service will start on `http://localhost:8080`.

-----

## Testing the service

You can test the service by sending a `multipart/form-data` request using a tool like cURL. The model provider will validate if the image matches the description.

### Sample request

```bash
curl -X POST http://localhost:8080/insurance/claims \
-F "description=Claim for a cracked phone screen." \
-F "image=@./resources/cracked_phone.jpeg"
```

### Sample responses

A successful request will receive a JSON response indicating whether the claim was `ACCEPTED` or `REJECTED`.

#### **Example of an ACCEPTED claim**

If the description and image are consistent:

```json
{
    "status": "ACCEPTED",
}
```

#### **Example of a REJECTED claim**
```json
{
    "status": "REJECTED",
    "reason": "The description mentions a cracked phone screen, but the image shows a damaged car."
}
```
