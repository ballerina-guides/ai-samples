# Ceate products in Shopify using sheets data

In this sample use case,
Read product descriptions from a Google Sheet.
For the lasted added product (read the last line in the Google sheet), call OpenAI text completion API to generate a product description.
Call OpenAI image generation API to generate a product image.
Call Shopify API and create a new product.


 ## Prerequisites
 * OpenAI account
 * Google sheets API
 * Shopify API

 ### Setting up an OpenAI account
 1. Create an [OpenAI](https://platform.openai.com/) account.
 2. Go to **View API keys** and create a new secret key.

 ### Obtain Google sheet API credentials
 Follow the steps mentioned in https://ei.docs.wso2.com/en/latest/micro-integrator/references/connectors/google-spreadsheet-connector/get-credentials-for-google-spreadsheet/#get-credentials-for-google-sheets 

 ### Obtain Shopify API credentials
 Obtain the authentication from the https://shopify.dev/docs/apps/auth

 ## Configuration
 Create a file called `Config.toml` at the root of the project.

 ### Config.toml
 ```
 openAIToken="<OPENAI_API_KEY>"
 sheetsAccessToken="<SHEETS_ACCESS_TOKEN>"
 googleSheetId = "<GOOGLE_SHEET_ID>"
 shopifyToken = "<SHOPIFY_TOKEN>"
 shopifyStoreURL = "<SHOPIFY_STORE_URL>"
 ```

