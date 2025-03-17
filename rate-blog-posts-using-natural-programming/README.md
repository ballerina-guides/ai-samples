# Blog Review with Natural Programming

This project demonstrates how to use **Ballerina's Runtime Prompt-as-Code** feature. The example uses natural language prompts to analyze blog content, suggest categories, and rate blog posts based on predefined criteria.

---

## Prerequisites

1. Install **Ballerina 2201.12.0** or higher.  
   Download and install Ballerina from [here](https://ballerina.io/downloads/).
2. Install the **Ballerina extension** for Visual Studio Code.

---

## Steps to Run

### **Option 1: Simplified Setup (Recommended for Beginners)**

#### 1. Login to WSO2 Ballerina Copilot

- Log in to your WSO2 Ballerina Copilot account.

#### 2. Configure Default Model for Natural Functions

- Press `Ctrl + Shift + P` (or `Cmd + Shift + P` on macOS) to open the command palette.
- Search for and select **"Configure Default Model for Natural Functions"**.
- Your API keys will be automatically generated and added to the `Config.toml` file in your project directory.

#### 3. Run the Program

- Open a terminal in the project directory.
- Run the following command:

  ```bash
  bal run
  ```

---

### **Option 2: Manual Configuration (Advanced Users)**

#### 1. Configure the Model in `Config.toml`

- Add the following configuration to your `Config.toml` file for Azure OpenAI (or your preferred LLM provider):
  
  ```toml
  [ballerinax.np.defaultModelConfig]
  serviceUrl = "<SERVICE_URL>"
  deploymentId = "<DEPLOYMENT_ID>"
  apiVersion = "<API_VERSION>"
  connectionConfig.auth.apiKey = "<YOUR_API_KEY>"
  ```

#### 2. Initialize the Model in Code (Optional)

- If you need more control over the model, you can initialize it in your code and pass it as a parameter:

  ```ballerina
  configurable string apiKey = ?;
  configurable string serviceUrl = ?;
  configurable string deploymentId = ?;
  configurable string apiVersion = ?;

  final np:Model azureOpenAIModel = check new np:AzureOpenAIModel({
      serviceUrl, connectionConfig: {auth: {apiKey}}}, deploymentId, apiVersion);

  Review review = check reviewBlog(blog, {model: azureOpenAIModel});
  ```

#### 3. Run the Program

- Open a terminal in the project directory.
- Run the following command:

  ```bash
  bal run
  ```

---

## Example Output

```bash
Blog 1 Review: {"suggestedCategory":"Gardening","rating":9}
Blog 2 Review: {"suggestedCategory":"Sports","rating":8}
```

---
