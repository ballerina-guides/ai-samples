type ChannelThread record {|
    string guild_id;
    string id;
    string name;
    json...;
|};

type ActiveThreads record {|
    ChannelThread[] threads;
    json...;
|};

type Channel record {|
    string guild_id;
    int 'type;
    json...;
|};

type Author record {|
    string username;
    json...;
|};

type Message record {|
    string content;
    Author author;
    string timestamp;
    json...;
|};
