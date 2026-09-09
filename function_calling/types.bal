type ParamterSchema record {
    string 'type;
    map<Property> properties;
    string[] required;
    boolean additionalProperties;
};

type Property record {
    string 'type;
    string description;
};
