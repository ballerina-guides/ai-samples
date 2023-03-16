import ballerina/http;
import ballerinax/googleapis.gmail;
import ballerinax/openai.dalle; // the names will change in th final connectors
import ballerinax/openai.gpt3; // the names will change in th final connectors

configurable string openAIToken = ?;
configurable string gmailToken = ?;

final gpt3:Client gpt3Client = check new ({auth: {token: openAIToken}});
final dalle:Client dalleClient = check new ({auth: {token: openAIToken}});
final gmail:Client gmailClient = check new ({auth: {token: gmailToken}});

type Reqquest record {|
    string occasion;
    string recipientEmail;
    string emailSubject;
    string specialNotes?;
|};

service / on new http:Listener(8080) {
    resource function post greetingCard(@http:Payload Reqquest req) returns error? {

        string occasion = req.occasion;
        string recipientEmail = req.recipientEmail;
        string emailSubject = req.emailSubject;
        string specialNotes = req.specialNotes ?: "";

        fork {
            // Parallelly generate greeting text and design
            worker contentWorker returns string?|error {
                string contentPrompt = string `Generate a greeting for a/an ${occasion}.\nSpecial notes: ${specialNotes}`;
                gpt3:CreateCompletionRequest textPrompt = {
                    prompt: contentPrompt,
                    model: "text-davinci-003",
                    max_tokens: 100
                };
                gpt3:CreateCompletionResponse completionRes = check gpt3Client->/completions.post(textPrompt);
                return completionRes.choices[0].text;
            }
            worker designWorker returns string?|error {
                string designPrompt = string `Greeting card design for ${occasion}, ${specialNotes}`;
                dalle:CreateImageRequest imagePrompt = {
                    prompt: designPrompt
                };
                dalle:ImagesResponse imageRes = check dalleClient->/images/generations.post(imagePrompt);
                return imageRes.data[0].url;
            }
        }

        map<string?|error> responses = wait {contentWorker, designWorker};
        string|error? greeting = responses["contentWorker"];
        string|error? image = responses["designWorker"];

        if (greeting is string && image is string) {
            // Send an email with the greeting and the image using the email connector
            string userId = "me";
            string htmlBody = "<p>" + greeting + "</p> <br/> <img src=" + image + ">";

            gmail:MessageRequest messageRequest = {
                recipient: recipientEmail,
                subject: emailSubject,
                messageBody: htmlBody,
                contentType: gmail:TEXT_HTML
            };
            gmail:Message _ = check gmailClient->sendMessage(messageRequest, userId = userId);
        }
    }
}
