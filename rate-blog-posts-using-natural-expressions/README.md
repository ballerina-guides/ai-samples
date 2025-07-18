# Blog Review with Natural Expressions

This project demonstrates how to use natural expressions in Ballerina, which allow you to specify logic in natural language. Such an expression is evaluated at runtime with a call to an LLM and returns a typed response automatically structured and bound to your expected format. The example uses a natural expression/function to analyze the content of a blog to suggest a category and rate it based on predefined criteria.

---

## Prerequisites

1. Install **Ballerina 2201.13.0-m3** or higher.  

    Download and install Ballerina from [here](https://ballerina.io/downloads/). Switch to a specific version using the `bal dist use` command.

    ```cmd
    $ bal dist use 2201.13.0-m3
    ```

2. Install the **Ballerina extension** for Visual Studio Code.

---

## Steps to Run

### **Option 1: Use the default model (without your own LLM keys)**

This approach is made available to quickly get up and running with natural expressions. Note that this is only meant to be used for trying out, and that for development and production use-cases, you would have to provide your keys.

#### 1. Log in to WSO2 Copilot

- Log in to your WSO2 Copilot account.

#### 2. Configure the Default Model for Natural Expressions

- Press `Ctrl + Shift + P` (or `Cmd + Shift + P` on macOS) to open the command palette.
- Search for and select **"Configure Default Model for Natural Functions"**.
- Your configuration will be automatically generated and added to the `Config.toml` file in your project directory.

#### 3. Run the Program

- Open a terminal in the project directory.
- Run the following command:

  ```bash
  bal run
  ```

---

### **Option 2: Using your own LLM keys**

You can use your own LLM keys with a model provider from the relevant `ballerinax/ai.<provider>` package (e.g., `ballerinax/ai.openai`, `ballerinax/ai.azure`, etc.).

For example, you can use an Open AI model as follows.

```ballerina
import ballerina/ai;
import ballerinax/ai.openai;

configurable string apiKey = ?;

final ai:ModelProvider openAiModel = check new openai:ModelProvider(apiKey, openai:GPT_4O);

public isolated function reviewBlog(Blog blog) returns Review|error => natural (openAiModel) {
    You are an expert content reviewer for a blog site that 
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
    Content: ${blog.content}
};

Review review = check reviewBlog(blog);
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

Use the following JSON payload in a request to the API:

```json
{
    "title": "Tips for Growing a Beautiful Garden",
    "content": "Spring is the perfect time to start your garden. Begin by preparing your soil with organic compost and ensure proper drainage. Choose plants suitable for your climate zone, and remember to water them regularly. Don't forget to mulch to retain moisture and prevent weeds."
}
```

#### **Response**

A response will contain a payload similar to the following, indicating the suggested category and rating for the blog post:

```json
{
  "suggestedCategory": "Gardening",
  "rating": 9
}
```

---
