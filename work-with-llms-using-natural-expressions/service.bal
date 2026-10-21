import ballerina/ai;
import ballerina/constraint;
import ballerina/http;
import ballerina/log;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;

final ai:ModelProvider model = check new openai:ModelProvider(openAiApiKey, openai:GPT_4O);

const MAX_ATTRACTIONS = 10;

# Represents a tourist attraction.
type Attraction record {|
    # The name of the attraction
    @constraint:String {minLength: 1}
    string name;
    # The city where the attraction is located
    @constraint:String {minLength: 1}
    string city;
    # A notable feature or highlight of the attraction, in one sentence
    @constraint:String {minLength: 1, maxLength: 250}
    string highlight;
|};

service on new http:Listener(8080) {
    resource function get attractions(string country, string interest, int count = 5)
            returns Attraction[]|http:BadRequest|http:BadGateway {
        if count < 1 || count > MAX_ATTRACTIONS {
            return <http:BadRequest>{body: string `count must be between 1 and ${MAX_ATTRACTIONS}`};
        }

        Attraction[]|error attractions = natural (model) {
            Tell me the top ${count} places to visit in ${country} which are
            good for a tourist who has an interest in ${interest} to visit.
            Include a highlight one-liner about that place.
        };

        if attractions is error {
            log:printError("Failed to generate attractions", attractions);
            return <http:BadGateway>{body: "Could not generate attractions"};
        }

        Attraction[]|error validated = validateAttractions(attractions, count);
        if validated is error {
            log:printWarn("Model response failed validation", 'error = validated);
            return <http:BadGateway>{body: "Could not generate valid attractions"};
        }
        return validated;
    }
}

# Validates attractions returned by the model before they are used.
#
# + attractions - The attractions bound from the model response
# + count - The number of attractions requested
# + return - The validated attractions, or an error if validation fails
isolated function validateAttractions(Attraction[] attractions, int count) returns Attraction[]|error {
    Attraction[] validated = check constraint:validate(attractions);
    if validated.length() == 0 {
        return error("model returned no attractions");
    }
    if validated.length() > count {
        return validated.slice(0, count);
    }
    return validated;
}
