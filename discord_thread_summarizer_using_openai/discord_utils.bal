import ballerina/time;
import ballerina/http;

const time:Seconds DISCORD_EPOCH = 1420070400000.00;

http:Client discordClient = check new (DISCORD_API_URL);

function getChannelDetails(int channelId) returns Channel|error {
    string path = string `/channels/${channelId}`;
    http:Response response = check discordClient->get(path, headers = {
        "Authorization": botToken
    });
    return (check response.getJsonPayload()).cloneWithType();
}

function getActiveThreads(string guildId) returns ActiveThreads|error {
    string path = string `/guilds/${guildId}/threads/active`;
    http:Response response = check discordClient->get(path, headers = {
        "Authorization": botToken
    });
    return (check response.getJsonPayload()).cloneWithType();
}

function getMessages(string threadId, string timestamp = "") returns Message[]|error {
    string path = string `/channels/${threadId}/messages`;

    if (timestamp != "") {
        path = string `/channels/${threadId}/messages?after=${timestamp}`;
    }
    http:Response response = check discordClient->get(path, headers = {
        "Authorization": botToken
    });
    return (check response.getJsonPayload()).cloneWithType();
}

function getThreadURL(string guildId, string threadId) returns string {
    return string `https://discord.com/channels/${guildId}/${threadId}`;
}

function reverseArray(Message[] arr) returns Message[] {
    int len = arr.length();
    Message[] result = [];
    foreach int i in 0 ..< len {
        result.push(arr[len - i - 1]);
    }
    return result;
}

function timestampToSnowflake(time:Utc timestamp, boolean high = true) returns int {
    // https://discord.com/developers/docs/reference#snowflakes-snowflake-id-format-structure-left-to-right
    // to fetch messages that are after a certain timestamp use high = true
    int discordMillis = <int>((<decimal>timestamp[0] + <decimal>timestamp[1]) * 1000 - DISCORD_EPOCH);
    return (discordMillis << 22) + (high ? 2 ^ 22 - 1 : 0);
}

