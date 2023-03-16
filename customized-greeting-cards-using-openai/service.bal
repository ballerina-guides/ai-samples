import ballerina/http;
import ballerinax/googleapis.gmail;
import ballerinax/openai.dalle; // the names will change in th final connectors
import ballerinax/openai.gpt3; // the names will change in th final connectors

configurable string openAIToken = ?;
configurable string gmailToken = ?;

final gpt3:Client gpt3Client = check new ({auth: {token: openAIToken}});
final dalle:Client dalleClient = check new ({auth: {token: openAIToken}});
final gmail:Client gmailClient = check new ({auth: {token: gmailToken}});

type GreetingDetails record {|
    string occasion;
    string recipientEmail;
    string emailSubject;
    string specialNotes?;
|};

service / on new http:Listener(8080) {
    resource function post greetingCard(@http:Payload GreetingDetails req) returns error? {

        string occasion = req.occasion;
        string specialNotes = req.specialNotes ?: "";

        fork {
            // Parallelly generate greeting text and design
            worker contentWorker returns string|error? {
                string prompt = string `Generate a greeting for a/an ${occasion}.${"\n"}Special notes: ${specialNotes}`;
                gpt3:CreateCompletionRequest textPrompt = {
                    prompt,
                    model: "text-davinci-003",
                    max_tokens: 100
                };
                gpt3:CreateCompletionResponse completionRes = check gpt3Client->/completions.post(textPrompt);
                return completionRes.choices[0].text;
            }
            worker designWorker returns string|error? {
                string prompt = string `Greeting card design for ${occasion}, ${specialNotes}`;
                dalle:CreateImageRequest imagePrompt = {
                    prompt
                };
                dalle:ImagesResponse imageRes = check dalleClient->/images/generations.post(imagePrompt);
                return imageRes.data[0].url;
            }
        }

        record {|
            string|error? contentWorker;
            string|error? designWorker;
        |} {contentWorker: greeting, designWorker: image} = wait {contentWorker, designWorker};

        if greeting !is string || image !is string {
            return error("Error while generating greeting card");
        }
        // Send an email with the greeting and the image using the email connector
        gmail:MessageRequest messageRequest = {
            recipient: req.recipientEmail,
            subject: req.emailSubject,
            messageBody: "<p>" + greeting + "</p> <br/> <img src=" + image + ">",
            contentType: gmail:TEXT_HTML
        };
        _ = check gmailClient->sendMessage(messageRequest, userId = "me");
    }
}
