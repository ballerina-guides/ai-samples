# Blog Review with Natural Functions

This project demonstrates how to use natural functions in Ballerina, which allow the function to contain instructions in natural language. Such a function is evaluated at runtime with a call to an LLM. The example uses a natural function to analyze blog content to suggest a category and rate it based on predefined criteria.

---

## Prerequisites

1. Install **Ballerina 2201.12.0** or higher.  
   Download and install Ballerina from [here](https://ballerina.io/downloads/).
2. Install the **Ballerina extension** for Visual Studio Code.

---

## Steps to Run

### **Option 1: Use the default model (Without LLM keys)**

This approach is made available to quickly get up and running with natural functions. Note that this is only meant to be used for trying out, and that for development and production use-cases, you would have to provide your keys.

#### 1.Login to WSO2 Copilot

- Log in to your WSO2 Copilot account.

#### 2.Configure the Default Model for Natural Functions

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

### **Option 2: Manual Configuration**

You can use one of the two following options to configure the LLM to use.

#### Option 2A: Configure the Model in the `Config.toml` file

- Add the model configuration to your `Config.toml` file.
  - For Azure OpenAI

    ```toml
    [ballerinax.np.defaultModelConfig]
    serviceUrl = "<SERVICE_URL>"
    deploymentId = "<DEPLOYMENT_ID>"
    apiVersion = "<API_VERSION>"
    connectionConfig.auth.apiKey = "<YOUR_API_KEY>"
    ```

  - For OpenAI

    ```toml
    [ballerinax.np.defaultModelConfig]
    serviceUrl = "<SERVICE_URL>"
    model = "<MODEL>"
    connectionConfig.auth.token = "<TOKEN>"
    ```

#### Option 2B: Initialize the Model in the Code

- If you need more control over the model by function, you can add the `np:Context context` parameter which allows setting the model. You can then initialize the model in your code and pass it as an argument to the context parameter.

  ```ballerina
  configurable string apiKey = ?;
  configurable string serviceUrl = ?;
  configurable string deploymentId = ?;
  configurable string apiVersion = ?;

  final np:Model azureOpenAIModel = check new np:AzureOpenAIModel({
      serviceUrl, connectionConfig: {auth: {apiKey}}}, deploymentId, apiVersion);

  public isolated function reviewBlog(
    Blog blog,
    np:Context context,
    np:Prompt prompt = `You are an expert content reviewer for a blog site that 
      categorizes posts under the following categories: ${categories}

      Your tasks are:
      1. Suggest a suitable category for the blog from exactly the specified categories. 
          If there is no match, use null.

      2. Rate the blog post on a scale of 1 to 10 based on the following criteria:
      - **Relevance**: How well the content aligns with the chosen category.
      - **Depth**: The level of detail and insight in the content.
      - **Clarity**: How easy it is to read and understand.
      - **Originality**: Whether the content introduces fresh perspectives or ideas.
      - **Language Quality**: Grammar, spelling, and overall writing quality.

      Here is the blog post content:

      Title: ${blog.title}
      Content: ${blog.content}`) returns Review|error = @np:NaturalFunction external;

  Review review = check reviewBlog(blog, {model: azureOpenAIModel});
  ```

#### 3. Run the Program

- Open a terminal in the project directory.
- Run the following command:

  ```bash
  bal run
  ```

---

### **Example Request and Response**

#### **Request Payload**
The following JSON payload was sent to the API:

```json
{
    "title": "Tips for Growing a Beautiful Garden",
    "content": "Spring is the perfect time to start your garden. Begin by preparing your soil with organic compost and ensure proper drainage. Choose plants suitable for your climate zone, and remember to water them regularly. Don't forget to mulch to retain moisture and prevent weeds."
}
```

#### **Response**
The API returned the following response, indicating the suggested category and rating for the blog post:

```json
{
  "suggestedCategory": "Gardening",
  "rating": 9
}
```

---
