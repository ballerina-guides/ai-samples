import ballerina/http;
import ballerinax/googleapis.gmail;
import ballerinax/openai.images;
import ballerinax/openai.text;

configurable string openAIToken = ?;
configurable string gmailToken = ?;

final text:Client openaiText = check new ({auth: {token: openAIToken}});
final images:Client openaiImages = check new ({auth: {token: openAIToken}});
final gmail:Client gmail = check new ({auth: {token: gmailToken}});

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
            // Generate greeting text and design in parallel
            worker contentWorker returns string|error? {
                string prompt = string `Generate a greeting for a/an ${occasion}.${"\n"}Special notes: ${specialNotes}`;
                text:CreateCompletionRequest textPrompt = {
                    prompt,
                    model: "text-davinci-003",
                    max_tokens: 100
                };
                text:CreateCompletionResponse completionRes = check openaiText->/completions.post(textPrompt);
                return completionRes.choices[0].text;
            }
            worker designWorker returns string|error? {
                string prompt = string `Greeting card design for ${occasion}, ${specialNotes}`;
                images:CreateImageRequest imagePrompt = {
                    prompt
                };
                images:ImagesResponse imageRes = check openaiImages->/images/generations.post(imagePrompt);
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
        _ = check gmail->sendMessage(messageRequest, userId = "me");
    }
}
