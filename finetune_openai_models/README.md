# Fine tune OpenAI models

This sample uploads a training data jsonl file to OpenAI and submits a fine tune job.

## Prerequisites
* OpenAI account

### Setting up OpenAI account
1. Create an [OpenAI](https://platform.openai.com/) account.
2. Go to **View API keys** and create new secret key.

## Configuration
Create a file called `Config.toml` at the root of the project.

### Config.toml
```
openAIToken="<OPENAI_API_KEY>"
```

### Preparing training data jsonl file
The training data jsonl file should contain `prompt` and `completion` pairs for each sample in each line. An example is added in the data directory. Please refer [prepare training data](https://platform.openai.com/docs/guides/fine-tuning) for more information.

### Obtaining predictions from the fine-tuned model
Generating predictions from the fine-tuned model can be done similar to any base model provided by OpenAI. You just have to specify the model id of the fine-tuned model in the `model` parameter of the request. 

```
public function main() returns error? {
    text:Client openAIText = check new ({auth: {token: openAIToken}});

    text:CreateCompletionRequest textPrompt = {
        prompt: "I am in such a good mood today ->",
        model: "ada:ft-xxxx"
    };

    text:CreateCompletionResponse completionRes = check openAIText->/completions.post(textPrompt);
    string? completion = completionRes.choices[0].text;

    if completion is string { 
        string emotion = regex:split(completion, " ")[1];
        io:println(string `Predicted emotion: ${emotion}`); 
    }
}
```

You can find the model id of the fine-tuned model by doing an API call to `openai.finetunes` as follows or by simply logging into the [playground](https://platform.openai.com/playground) of your OpenAI account.

```
public function main() returns error? {
    finetunes:Client openAIFineTunes = check new ({auth: {token: openAIToken}});
    finetunes:ListModelsResponse models = check openAIFineTunes->/models.get();
    io:print(models);
}
```