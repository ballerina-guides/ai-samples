import ballerina/io;
import ballerina/log;
import ballerina/time;

const TYPE_FORUM_CHANEL = 15;

configurable int forumChannelId = ?;

function readThreads(ActiveThreads activeThreads) returns error? {

    foreach ChannelThread thread in activeThreads.threads {

        // check if the thread has any recent messages
        if !check checkRecentMessages(thread) {
            continue;
        }

        string prompt = check constructPrompt(thread);
        io:println(prompt);

        string|error generateChatCompletionResult = generateChatCompletion(prompt);

        if generateChatCompletionResult is string {
            io:println(generateChatCompletionResult);
        } else {
            log:printError("Error occured when connecting to OpenAI: ", generateChatCompletionResult, stackTrace = generateChatCompletionResult.stackTrace());
        }
        io:println("--------------------------------------------------\n\n");
    }
}

function constructPrompt(ChannelThread thread) returns string|error {
    string prompt = string `${PROMPT}Thread URL: ${getThreadURL(thread.guild_id, thread.id)}${"\n"}Title: ${thread.name}${"\n"}Question: `;
    Message[] allMessages = check getMessages(thread.id);

    // reverse the array so that the messages are in chronological order
    allMessages = allMessages.reverse();

    boolean firstMessage = true;
    foreach Message message in allMessages {
        string formattedTimestamp = message.timestamp;
        if message.content == "" {
            io:println(string `The message from ${message.author.username} is empty.`);
        } else {
            // first message is the question
            if firstMessage {
                prompt += string `${message.content} (${formattedTimestamp})${"\n"}Reply: `;
                firstMessage = false;
            } else {
                prompt += string `${message.author.username}: ${message.content} (${formattedTimestamp})${"\n"}`;
            }
        }
    }
    return prompt;
}

function checkRecentMessages(ChannelThread thread) returns boolean|error {
    time:Utc oneDayAgoTime = time:utcAddSeconds(time:utcNow(), -86400);
    string snowflakeTime = timestampToSnowflake(oneDayAgoTime).toString();

    Message[] recentMessages = check getMessages(thread.id, snowflakeTime);

    // check if the thread has any recent messages
    return recentMessages.length() > 0;
}

public function main() returns error? {
    Channel channel = check getChannelDetails(forumChannelId);
    if channel.'type != TYPE_FORUM_CHANEL {
        io:println(string `The channel with ID ${forumChannelId} is not a Forum channel.`);
        return;
    }
    ActiveThreads activeThreads = check getActiveThreads(channel.guild_id);
    check readThreads(activeThreads);
}

