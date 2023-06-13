type ChannelThread record {
    string guild_id;
    string id;
    string name;
};

type ActiveThreads record {
    ChannelThread[] threads;
};

type Channel record {
    string guild_id;
    int 'type;
};

type Author record {
    string username;
};

type Message record {
    string content;
    Author author;
    string timestamp;
};
