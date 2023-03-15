import ballerinax/shopify.admin as shopify;
import ballerinax/googleapis.sheets;
import ballerina/http;
// import ballerina/io;

// Google Sheets API client configuration
configurable string gsheetToken = ?;
configurable string gsheetsClientID = ?;
configurable string gsheetsClientSecret = ?;
configurable string gsheetsRefreshToken = ?;

// OpenAI token
configurable string openAIToken = ?;

// Shopify token 
configurable string shopifyToken = ?;
configurable string shopifyStoreURL = ?;

// Google Sheets client configuration
sheets:Client sheetsEp = check new (config = {
    auth: {
        refreshUrl: sheets:REFRESH_URL,
        clientId: gsheetsClientID,
        clientSecret: gsheetsClientSecret,
        refreshToken: gsheetsRefreshToken
    }
});

// OpenAI API client configuration
http:Client openAI = check new ("https://api.openai.com");

// Shopify client configuration
shopify:Client shopifyEp = check new (apiKeyConfig = {
    xShopifyAccessToken: shopifyToken
}, serviceUrl = shopifyStoreURL);

// Product record
type Product record {
    string name;
    string benefits;
    string features;
    string usedBy;
    string price;
    string productType;
};

type OpenAIImagePrompt record {
    string prompt;
    int n = 1;
    string size = "256x256";
};

// OpenAI Prompt record
type OpenAICompletionPrompt record {
    string model = "text-davinci-003";
    string prompt;
    float temperature = 0.7;
    int max_tokens = 256;
    float top_p = 1;
    int frequency_penalty = 0;
    int presence_penalty = 0;
};

type OpenAICompletionChoicesItem record {
    string text;
    int index;
    anydata logprobs;
    string finish_reason;
};

type OpenAICompletionUsage record {
    int prompt_tokens;
    int completion_tokens;
    int total_tokens;
};

type OpenAICompletionResponse record {
    string id;
    string 'object;
    int created;
    string model;
    OpenAICompletionChoicesItem[] choices;
    OpenAICompletionUsage usage;
};

type OpenAIImageDataItem record {
    string url;
};

type OpenAIImageResponse record {
    int created;
    OpenAIImageDataItem[] data;
};

// Returns a Product object from a row in the Google Sheet
function getProduct((int|string|decimal)[] row) returns Product {
    Product product = {
        name: <string> row[0],
        benefits: <string> row[1],
        features: <string> row[2],
        usedBy: <string> row[3],
        price: <string> row[4],
        productType: <string> row[5]
    };
    return product;
}

// Google Sheet ID
const string SHEET_ID = "1w_Z9oQ6Lwyz8cn2N-LiX2pWVSKAVM7N4WkcR-Zkrm74";

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # A resource for generating greetings
    # + return - int name with hello message or error
    resource function get createProductInShopify() returns int|error {
        // Get the last inserted row from the Google Sheet and convert it to a product
        sheets:Range response = check sheetsEp->getRange(SHEET_ID, "Sheet1", "A2:F");
        int lastRowIndex = response.values.length() -1;
        Product lastInsertedProduct = getProduct(response.values[lastRowIndex]);

        // Generate a product description from OpenAI for a given product name
        OpenAICompletionPrompt prmt = {
            prompt: "generate a product descirption in 250 words about " + lastInsertedProduct.name
        };   
        OpenAICompletionResponse completionRes = check openAI->post("/v1/completions", prmt, { "Authorization": "Bearer " + openAIToken});
        string productDescription = completionRes.choices[0].text;

        // Generate a product image from OpenAI for the given product
        OpenAIImagePrompt prmtImg = {
            prompt: lastInsertedProduct.name + ", " + lastInsertedProduct.benefits + ", " + lastInsertedProduct.features
        };
        OpenAIImageResponse ImageRes = check openAI->post("/v1/images/generations", prmtImg, { "Authorization": "Bearer " + openAIToken});
        string productImageURL  = ImageRes.data[0].url;
        
        // Create product in Shopify
        shopify:CreateProduct myProduct = {
            product: {
                title: lastInsertedProduct.name,
                body_html: productDescription,
                tags: lastInsertedProduct.features,
                product_type: lastInsertedProduct.productType,
                images: [{src: productImageURL}]
            }
        };

        shopify:ProductObject prodObj = check shopifyEp->createProduct(myProduct);
        int? pid = prodObj?.product?.id;
        if (pid is ()) {
            return error("Error creating product in Shopify");
        } else {
            return pid;
        }
    }
}
