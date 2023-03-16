import ballerina/http;
import ballerinax/googleapis.sheets;
import ballerinax/shopify.admin as shopify;

configurable string sheetsAccessToken = ?;
configurable string googleSheetId = ?;

configurable string openAIToken = ?;

configurable string shopifyToken = ?;
configurable string shopifyStoreURL = ?;

sheets:Client gsheets = check new ({auth: {token: sheetsAccessToken}});

final http:Client openAI = check new ("https://api.openai.com");

final shopify:Client shopify = check new (apiKeyConfig = {xShopifyAccessToken: shopifyToken},
serviceUrl = shopifyStoreURL);

final map<string> openAIHeaders = {
    "Authorization": "Bearer " + openAIToken
};

type ImagePrompt record {|
    string prompt;
    int n = 1;
    string size = "256x256";
|};

type CompletionPrompt record {|
    string model = "text-davinci-003";
    string prompt;
    float temperature = 0.7;
    int max_tokens = 256;
    float top_p = 1;
    int frequency_penalty = 0;
    int presence_penalty = 0;
|};

type Completion record {
    Choice[] choices;
};

type Choice record {
    string text;
};

type Image record {
    ImageData[] data;
};

type ImageData record {
    string url;
};

service / on new http:Listener(9090) {

    resource function post products() returns int|error {
        // Get the product details from the last inserted row of the Google Sheet.
        sheets:Range range = check gsheets->getRange(googleSheetId, "Sheet1", "A2:F");
        var [name, benefits, features, productType] = getProduct(range);

        // Generate a product description from OpenAI for a given product name.
        CompletionPrompt completionPrmt = {prompt: string `generate a product descirption in 250 words about ${name}`};
        Completion completion = check openAI->/v1/completions.post(completionPrmt, openAIHeaders);

        // Generate a product image from OpenAI for the given product.
        ImagePrompt imagePrmt = {prompt: string `${name}, ${benefits}, ${features}`};
        Image image = check openAI->/v1/images/generations.post(imagePrmt, openAIHeaders);

        // Create a product in Shopify.
        shopify:CreateProduct product = {
            product: {
                title: name,
                body_html: completion.choices[0].text,
                tags: features,
                product_type: productType,
                images: [{src: image.data[0].url}]
            }
        };
        shopify:ProductObject prodObj = check shopify->createProduct(product);
        int? pid = prodObj?.product?.id;
        if pid is () {
            return error("Error in creating product in Shopify");
        }
        return pid;
    }
}

function getProduct(sheets:Range range) returns [string, string, string, string] {
    int lastRowIndex = range.values.length() - 1;
    (int|string|decimal)[] row = range.values[lastRowIndex];
    return [<string>row[0], <string>row[1], <string>row[2], <string>row[5]];
}
