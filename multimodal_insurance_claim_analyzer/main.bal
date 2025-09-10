import ballerina/ai;
import ballerina/http;
import ballerina/log;
import ballerina/mime;

enum Status {
    ACCEPTED,
    REJECTED
}

# Represents the final response for a claim validation request.
type ClaimResponse record {|
    # The final status of the claim (`ACCEPTED` or `REJECTED`)
    Status status;
    # Included only when the claim is `REJECTED`, providing the reason for rejection
    string reason?;
|};

final ai:Wso2ModelProvider modelProvider = check ai:getDefaultModelProvider();

service /insurance on new http:Listener(8080) {
    resource function post claims(http:Request request) returns ClaimResponse|error {
        mime:Entity[] bodyParts = check request.getBodyParts();

        string description = check bodyParts[0].getText();
        byte[] claimImage = check bodyParts[1].getByteArray();
        ai:ImageDocument claimImageDocument = {
            content: claimImage
        };

        ClaimResponse claimResonse = check modelProvider->generate(`
                You are an insurance claim validator. Your task is to determine if the user's
                claim description is consistent with the provided image.
                Consider a description valid if and only if the image strongly supports the description.

                Submitted description: ${description}
                Submitted image: ${claimImageDocument}
        `);

        if claimResonse.status == ACCEPTED {
            log:printInfo("Claim validated and accepted");
        } else {
            log:printInfo("Claim successfully validated and approved", reason = claimResonse.reason);
        }

        return claimResonse;
    }
}
