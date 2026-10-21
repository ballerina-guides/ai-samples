import ballerina/log;

# A claim as stored in the claims system. It contains data that the assistant does not need.
type Claim record {|
    string claimId;
    string policyholderId;
    string status;
    decimal amountClaimed;
    string lastUpdated;
    string nextStep;
    string email;
    string bankAccount;
    string adjusterNotes;
|};

# The subset of a claim that the assistant is allowed to see and send to the model.
type ClaimSummary record {|
    # The claim ID
    string claimId;
    # The current status of the claim
    string status;
    # The amount claimed, in USD
    decimal amountClaimed;
    # The date on which the claim was last updated, in the format YYYY-MM-DD
    string lastUpdated;
    # What happens next with the claim
    string nextStep;
|};

# A time window for a callback from a claims adjuster.
enum CallbackWindow {
    MORNING,
    AFTERNOON,
    EVENING
}

# A callback booked with a claims adjuster.
type Callback record {|
    # The callback reference
    string callbackId;
    # The claim the callback is about
    string claimId;
    # The booked time window
    CallbackWindow window;
|};

# An error returned by the claims API.
type ErrorBody record {
    string message;
};

# Information about a chat request that is written to the log.
# Fields marked `@log:Sensitive` are excluded from the log output when masking is enabled.
type ChatAuditEntry record {|
    string sessionId;
    @log:Sensitive
    string policyholderId;
    int messageLength;
    int redactedValues;
|};
