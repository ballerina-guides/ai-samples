import ballerina/io;
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

        string|error generateChatCompletionResult = generateChatCompletion(prompt, model = "gpt-3.5-turbo");

        if generateChatCompletionResult is string {
            io:println(generateChatCompletionResult);
        } else {
            io:println("Error: " + generateChatCompletionResult.toBalString());
        }
        io:println("--------------------------------------------------\n\n");
    }
}

function constructPrompt(ChannelThread thread) returns string|error {
    string prompt = PROMPT + "Thread URL: " + getThreadURL(thread.guild_id, thread.id.toString()) + "\nTitle: " + thread.name.toString() + "\nQuestion: ";
    Message[] allMessages = check getMessages(thread.id.toString());

    // reverse the array so that the messages are in chronological order
    allMessages = allMessages.reverse();

    boolean firstMessage = true;
    foreach Message message in allMessages {
        string formattedTimestamp = message.timestamp.toString();
        if message.content == "" {
            io:println("The message from " + message.author.username.toString() + " is empty.");
        } else {
            // first message is the question
            if firstMessage {
                prompt += message.content.toString() + " (" + formattedTimestamp + ")\nReply: ";
                firstMessage = false;
            } else {
                prompt += message.author.username.toString() + ": " + message.content.toString() + " (" + formattedTimestamp + ")\n";
            }
        }
    }
    return prompt;
}

function checkRecentMessages(ChannelThread thread) returns boolean|error {
    time:Utc oneDayAgoTime = time:utcAddSeconds(time:utcNow(), -86400);
    string snowflakeTime = timestampToSnowflake(oneDayAgoTime).toString();

    Message[] recentMessages = check getMessages(thread.id.toString(), snowflakeTime);

    // check if the thread has any recent messages
    return recentMessages.length() > 0;
}

public function main() returns error? {
    Channel channel = check getChannelDetails(forumChannelId);
    if channel.'type != TYPE_FORUM_CHANEL {
        io:println("The channel with ID " + forumChannelId.toString() + " is not a Forum channel.");
        return;
    }
    ActiveThreads activeThreads = check getActiveThreads(channel.guild_id);
    check readThreads(activeThreads);
}

