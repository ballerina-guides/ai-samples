import ballerinax/openai.gpt3; // the names will change in th final connectors
import ballerinax/openai.dalle; // the names will change in th final connectors
import ballerina/http;
import ballerinax/googleapis.gmail;
import ballerina/log;

// OpenAI token
configurable string openAIToken = ?;

// Gmail credentials
configurable string gmailToken = ?;
configurable string gmailClientID = ?;
configurable string gmailClientSecret = ?;
configurable string gmailRefreshToken = ?;

// Configure OpenAI gpt3 client
gpt3:Client gpt3Client = check new ({
    auth: {
        token: openAIToken
    }
});

// Configure OpenAI dalle client
dalle:Client dalleClient = check new ({
    auth: {
        token: openAIToken
    }
});

// Configure Gmail client
gmail:ConnectionConfig gmailConfig = {
    auth: {
        refreshUrl: gmail:REFRESH_URL,
        refreshToken: gmailRefreshToken,
        clientId: gmailClientID,
        clientSecret: gmailClientSecret
    }
};

gmail:Client gmailClient = check new (gmailConfig);

type Reqquest record {|
    string occasion;
    string recipientEmail;
    string emailSubject;
    string specialNotes?;
|};

service / on new http:Listener(8080) {
    resource function post sendGreeding(@http:Payload Reqquest req) returns error? {

        string occasion = req.occasion;
        string recipientEmail = req.recipientEmail;
        string emailSubject = req.emailSubject;
        string specialNotes = req.specialNotes ?: "";

        fork {
            worker contentWorker returns string|error {
                string contentPrompt = "Generate a greeting for a/an " + occasion + ".\nSpecial notes: " + specialNotes;

                gpt3:CreateCompletionRequest textPrompt = {
                    prompt: contentPrompt,
                    model: "text-davinci-003",
                    max_tokens: 100
                };
                gpt3:CreateCompletionResponse completionRes = check gpt3Client->/completions.post(textPrompt);

                string greeting = <string>completionRes.choices[0].text;
                log:printInfo("Greeting: " + greeting);

                return greeting;
            }
            worker designWorker returns string|error {
                string designPrompt = "Greeting card design for " + occasion + ", " + specialNotes;

                dalle:CreateImageRequest imagePrompt = {
                    prompt: designPrompt
                };

                dalle:ImagesResponse imageRes = check dalleClient->/images/generations.post(imagePrompt);
                string image = <string>imageRes.data[0].url;
                log:printInfo("Design URL: " + image);

                return image;
            }
        }

        map<string|error> responses = wait {contentWorker, designWorker};
        string|error? greeting = responses["contentWorker"];
        string|error? image = responses["designWorker"];

        if (greeting is string && image is string) {
            // Send an email with the greeting and the image using the email connector
            string userId = "me";
            string htmlBody = "<p>" + greeting + "</p> <br/> <img src=" + image + ">";

            gmail:MessageRequest messageRequest = {
                recipient : recipientEmail,
                subject : emailSubject,
                messageBody : htmlBody,
                contentType : gmail:TEXT_HTML
            };

            gmail:Message|error sendMessageResponse = check gmailClient->sendMessage(messageRequest, userId = userId);

            if (sendMessageResponse is gmail:Message) {
                log:printInfo("Sucessfully sent the email");
            } else {
                log:printError("An error occured while sending the email: ", 'error = sendMessageResponse);
            }
        }
        else if greeting is error {
            log:printError("An error occured while generating greeting: ", 'error = greeting);
        }
        else if image is error {
            log:printError("An error occured while generating design: ", 'error = image);
        }
    }
    
}
