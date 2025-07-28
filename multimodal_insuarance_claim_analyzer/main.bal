import ballerina/ai;
import ballerina/http;
import ballerina/mime;

enum submissionStatus {
    SUCCESS,
    FAILED
}

type ClaimResponse record {|
    submissionStatus submissionStatus;
    string summary?;
|};

# Claims Processing API Service
#
# This service provides endpoints for processing insurance claims with AI-powered analysis.
service /insuarance on new http:Listener(8080) {

    # Process a new insurance claim submission
    #
    # This resource function accepts multipart form data containing a claim description
    # and an associated image. It uses AI model providers to analyze the content and
    # generate an intelligent summary of the claim.
    #
    # + request - HTTP request containing multipart form data with:
    # - First part: Text description of the claim
    # - Second part: Binary image data related to the claim
    # + return - ClaimResponse containing submission status and AI-generated summary,
    # or an error if processing fails
    resource function post claims(http:Request request) returns ClaimResponse|error {
        mime:Entity[] bodyParts = check request.getBodyParts();

        string description = check bodyParts[0].getText();
        byte[] claimImage = check bodyParts[1].getByteArray();
        ai:ImageDocument claimImageDocument = {
            content: claimImage
        };

        ai:Wso2ModelProvider modelProvider = check ai:getDefaultModelProvider();
        string summary = check modelProvider->generate(
            `Please summarize the following claim
                - Description: ${description}
                - Image of the claim: ${claimImageDocument}`);
        return {
            submissionStatus: SUCCESS,
            summary
        };
    }
}
