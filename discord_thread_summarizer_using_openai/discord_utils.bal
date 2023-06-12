import ballerina/http;
import ballerina/time;

const DISCORD_API_URL = "https://discord.com/api/v9";
const time:Seconds DISCORD_EPOCH = 1420070400000.00;
configurable string botToken = ?;

final http:Client discordClient = check new (DISCORD_API_URL);

function getChannelDetails(int channelId) returns Channel|error {
    return discordClient->get(string `/channels/${channelId}`, headers = {
        "Authorization": botToken
    });
}

function getActiveThreads(string guildId) returns ActiveThreads|error {
    return discordClient->get(string `/guilds/${guildId}/threads/active`, headers = {
        "Authorization": botToken
    });
    
}

function getMessages(string threadId, string? timestamp = ()) returns Message[]|error {
    string path = string `/channels/${threadId}/messages`;

    if timestamp != () {
        path = string `/channels/${threadId}/messages?after=${timestamp}`;
    }
    return discordClient->get(path, headers = {
        "Authorization": botToken
    });
}

function getThreadURL(string guildId, string threadId) returns string {
    return string `https://discord.com/channels/${guildId}/${threadId}`;
}

function timestampToSnowflake(time:Utc timestamp, boolean high = true) returns int {
    // https://discord.com/developers/docs/reference#snowflakes-snowflake-id-format-structure-left-to-right
    // to fetch messages that are after a certain timestamp use high = true
    int discordMillis = <int>((<decimal>timestamp[0] + <decimal>timestamp[1]) * 1000 - DISCORD_EPOCH);
    return (discordMillis << 22) + (high ? 2 ^ 22 - 1 : 0);
}

