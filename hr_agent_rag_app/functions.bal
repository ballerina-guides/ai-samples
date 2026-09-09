import ballerinax/azure.openai.chat;
import ballerinax/pinecone.vector;

public type Metadata record {
    string text;
};

public type ChatResponseChoice record {|
    chat:ChatCompletionResponseMessage message?;
    chat:ContentFilterChoiceResults content_filter_results?;
    int index?;
    string finish_reason?;
    anydata...;
|};


isolated function augment(vector:QueryMatch[] matches) returns string|error {
    string context = "";
    foreach vector:QueryMatch data in matches {
        Metadata metadata = check data.metadata.cloneWithType();
        context = context.concat(metadata.text);
    }
    return context;
}

function decimalToFloatArray(decimal[] decimalArray) returns float[] {
    float[] floatArray = [];
    foreach decimal d in decimalArray {
        floatArray.push(<float>d);
    }
    return floatArray;
}
