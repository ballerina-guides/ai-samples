# E-commerce product filtering with compile-time code generation

This project demonstrates Large Language Model (LLM)-powered compile-time code generation in Ballerina. This feature allows you to define a function's logic in natural language. During compilation, an LLM generates the corresponding Ballerina code. This example uses this feature to generate the logic for filtering products in a simple e-commerce API.

-----

## Prerequisites

1.  Install **Ballerina 2201.13.0-m3** or higher.
    You can download and install Ballerina from [here](https://ballerina.io/downloads/). To switch to a specific version, use the `bal dist use` command.

    ```bash
    bal dist use 2201.13.0-m3
    ```

2.  Install the **Ballerina extension** for Visual Studio Code.

-----

## Steps to run

#### 1\. Log in to WSO2 copilot

Use the VS Code command palette to log in to your WSO2 Copilot account.

#### 2\. Get your credentials

  - Press `Ctrl + Shift + P` (or `Cmd + Shift + P` on macOS) to open the command palette.
  - Search for and select **"Ballerina: Configure default WSO2 model provider"**.
  - This will write your credentials into the `Config.toml` file. **Copy the service URL and access token** from this file for the next step.

#### 3\. Set environment variables

You need to set the following environment variables in your terminal. Use the values you copied in the previous step.

**For macOS/Linux:**

```bash
export BAL_CODEGEN_URL="<PASTE_THE_URL_HERE>"
export BAL_CODEGEN_TOKEN="<PASTE_THE_TOKEN_HERE>"
```

**For Windows (Command Prompt):**

```cmd
set BAL_CODEGEN_URL="<PASTE_THE_URL_HERE>"
set BAL_CODEGEN_TOKEN="<PASTE_THE_TOKEN_HERE>"
```

#### 4\. Run the program

  - Open a new terminal in the project directory.
  - Run the following command to start the service:
    ```bash
    $ bal run
    ```
-----

#### 5\. Run the test

  - Open a new terminal in the project directory.
  - Run the following command to run the tests:
    ```bash
    $ bal test
    ```
  - The test data is generated at compile time using Ballerina's `const natural` expression feature.
-----

## Sample request and response

You can test the running service by sending a `GET` request to the `/shop/products/filter` endpoint with a `minPrice` query parameter.

### Request

This example filters products with a price greater than `100`.

```bash
$ curl "http://localhost:8080/products/filter?minPrice=100.00"
```

### Response

The response payload will be a JSON array containing the products with a price greater than 100.

```json
[
    {
        "id": "PROD001",
        "price": 999.99
    },
    {
        "id": "PROD002",
        "price": 699.99
    }
]
```
-----
