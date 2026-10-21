// Patterns for values that must not be sent to the model provider.
// Card numbers are checked before phone numbers, because a card number also matches the phone pattern.
final readonly & [string:RegExp, string][] PII_PATTERNS = [
    [re `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`, "[EMAIL]"],
    [re `[0-9](?:[ -]?[0-9]){12,18}`, "[CARD_NUMBER]"],
    [re `\+?[0-9][0-9 ()-]{7,}[0-9]`, "[PHONE_NUMBER]"]
];

# Replaces email addresses, card numbers, and phone numbers in a message with placeholders.
#
# + message - The message received from the user
# + return - The redacted message and the number of values that were replaced
isolated function redactPii(string message) returns [string, int] {
    string redacted = message;
    int count = 0;
    foreach [string:RegExp, string] [pattern, placeholder] in PII_PATTERNS {
        count += pattern.findAll(redacted).length();
        redacted = pattern.replaceAll(redacted, placeholder);
    }
    return [redacted, count];
}

# Maps a claim from the claims system to the fields that the assistant may use.
#
# + claim - The claim returned by the claims system
# + return - The claim summary
isolated function toClaimSummary(Claim claim) returns ClaimSummary => {
    claimId: claim.claimId,
    status: claim.status,
    amountClaimed: claim.amountClaimed,
    lastUpdated: claim.lastUpdated,
    nextStep: claim.nextStep
};
