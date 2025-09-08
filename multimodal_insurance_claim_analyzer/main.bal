import ballerina/ai;
import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/uuid;

enum Status {
    ACCEPTED,
    REJECTED
}

type ValidationResponse record {|
    boolean isValid;
    string reason;
|};

type ClaimResponse record {|
    string claimId;
    Status status;
    string reason;
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

        ValidationResponse validation = check modelProvider->generate(`
                You are an insurance claim validator. Your task is to determine if the user's
                claim description is consistent with the provided image. 
                
                Respond ONLY with a JSON object containing two fields: "isValid" (boolean) and "reason" (string).
                - Set "isValid" to true if the image strongly supports the description.
                - Set "isValid" to false if there is a mismatch or ambiguity.
                - The "reason" should be a concise, one-sentence explanation for your decision.

                Claim Description: ${description}
                Image of the claim: ${claimImageDocument}
        `);

        string claimId = uuid:createRandomUuid();
        Status status = validation.isValid ? ACCEPTED : REJECTED;

        if status == ACCEPTED {
            log:printInfo("Claim validated and accepted", claimId = claimId, reason = validation.reason);
        } else {
            log:printInfo("Claim validation failed and was rejected", reason = validation.reason);
        }

        return {
            claimId,
            status,
            reason: validation.reason
        };
    }
}
