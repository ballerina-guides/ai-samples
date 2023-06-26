import ballerina/io;
import ballerina/log;
import ballerina/time;

const TYPE_FORUM_CHANEL = 15;
const time:Seconds ONE_DAY_IN_SECONDS = 86400;

configurable int forumChannelId = ?;

function readThreads(ActiveThreads activeThreads) returns error? {

    foreach ChannelThread thread in activeThreads.threads {

        if !check hasRecentMessages(thread) {
            continue;
        }

        string prompt = check constructPrompt(thread);

        string|error generateChatCompletionResult = generateChatCompletion(prompt);

        if generateChatCompletionResult is string {
            io:println(generateChatCompletionResult);
        } else {
            log:printError("Error occured when connecting to OpenAI: ",
            generateChatCompletionResult,
            stackTrace = generateChatCompletionResult.stackTrace());
        }
        io:println("--------------------------------------------------\n\n");
    }
}

function constructPrompt(ChannelThread thread) returns string|error {
    string prompt = string `${PROMPT}Thread URL: ${getThreadURL(thread.guild_id, thread.id)}${"\n"}Title: ${thread.name}${"\n"}Question: `;
    Message[] allMessages = (check getMessages(thread.id)).reverse();

    boolean firstMessage = true;
    foreach Message message in allMessages {
        string formattedTimestamp = message.timestamp;
        if message.content == "" {
            io:println(string `The message from ${message.author.username} is empty.`);
            continue;
        }
        if firstMessage {
            prompt += string `${message.content} (${formattedTimestamp})${"\n"}Reply: `;
            firstMessage = false;
            continue;
        }
        prompt += string `${message.author.username}: ${message.content} (${formattedTimestamp})${"\n"}`;

    }
    return prompt;
}

function hasRecentMessages(ChannelThread thread) returns boolean|error {
    time:Utc oneDayAgoTime = time:utcAddSeconds(time:utcNow(), -ONE_DAY_IN_SECONDS);
    string snowflakeTime = timestampToSnowflake(oneDayAgoTime).toString();
    Message[] recentMessages = check getMessages(thread.id, snowflakeTime);
    return recentMessages.length() > 0;
}

public function main() returns error? {
    Channel channel = check getChannelDetails(forumChannelId);
    if channel.'type != TYPE_FORUM_CHANEL {
        log:printError(string `The channel with ID ${forumChannelId} is not a Forum channel.`);
        return;
    }
    ActiveThreads activeThreads = check getActiveThreads(channel.guild_id);
    check readThreads(activeThreads);
}
