import ballerina/ai;
import ballerina/http;
import ballerina/log;

configurable string claimsApiUrl = "http://localhost:9090/api";
// Each tool calls the claims API with its own credential, which grants only what that tool needs.
configurable string claimsReadToken = ?;
configurable string callbackWriteToken = ?;

const POLICYHOLDER_ID = "policyholderId";
const BACKEND_UNAVAILABLE = "backendUnavailable";
const TOOL_ACCESS_DENIED = "toolAccessDenied";

final http:Client claimsReader = check new (claimsApiUrl, auth = {token: claimsReadToken}, timeout = 10);
final http:Client callbackWriter = check new (claimsApiUrl, auth = {token: callbackWriteToken}, timeout = 10);

# Retrieves the status of one of the current user's insurance claims.
#
# + ctx - The agent context, which identifies the authenticated policyholder
# + claimId - The claim ID, in the format CLM-12345
# + return - A summary of the claim, or an error that describes why it could not be retrieved
@ai:AgentTool
isolated function getClaimStatus(ai:Context ctx, string claimId) returns ClaimSummary|error {
    check validateClaimId(claimId);
    // The policyholder comes from the validated token, never from the model.
    string policyholderId = check ctx.getWithType(POLICYHOLDER_ID);
    Claim|http:ClientError claim = claimsReader->/policyholders/[policyholderId]/claims/[claimId];
    if claim is http:ClientError {
        return toToolError(ctx, claim);
    }
    return toClaimSummary(claim);
}

# Books a callback from a claims adjuster about one of the current user's claims.
# Call this only when the user asks to speak to an adjuster.
#
# + ctx - The agent context, which identifies the authenticated policyholder
# + claimId - The claim ID, in the format CLM-12345
# + window - The time window that the user prefers for the callback
# + return - The booked callback, or an error that describes why it could not be booked
@ai:AgentTool
isolated function requestCallback(ai:Context ctx, string claimId, CallbackWindow window) returns Callback|error {
    check validateClaimId(claimId);
    string policyholderId = check ctx.getWithType(POLICYHOLDER_ID);
    Callback|http:ClientError callback =
        callbackWriter->/policyholders/[policyholderId]/claims/[claimId]/callbacks.post({window});
    if callback is http:ClientError {
        return toToolError(ctx, callback);
    }
    return callback;
}

# Validates a claim ID before it is sent to the claims API.
#
# + claimId - The claim ID provided by the model
# + return - An error if the claim ID is not in the format CLM-12345
isolated function validateClaimId(string claimId) returns error? {
    if !re `CLM-[0-9]{5}`.isFullMatch(claimId) {
        return error(string `'${claimId}' is not a valid claim ID. Claim IDs have the format CLM-12345.`);
    }
}

# Converts a claims API error into an error message for the model.
# A rejected credential (401 or 403) and an unavailable backend are recorded in the context,
# so that the service fails the request instead of relying on the model's answer.
#
# + ctx - The agent context
# + err - The error returned by the HTTP client
# + return - The error to return to the model
isolated function toToolError(ai:Context ctx, http:ClientError err) returns error {
    if err is http:ClientRequestError {
        int status = err.detail().statusCode;
        if status == http:STATUS_UNAUTHORIZED || status == http:STATUS_FORBIDDEN {
            log:printError("The claims API rejected the tool credential", statusCode = status);
            ctx.set(TOOL_ACCESS_DENIED, true);
            return error("The claims system denied access.");
        }
        ErrorBody|error body = err.detail().body.ensureType();
        return error(body is ErrorBody ? body.message : "The request was rejected by the claims system.");
    }
    log:printError("The claims API is unavailable", err);
    ctx.set(BACKEND_UNAVAILABLE, true);
    return error("The claims system is temporarily unavailable.");
}
