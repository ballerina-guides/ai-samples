# Evaluate agent behavior

A broadband support agent built with `ballerina/ai`, together with an evaluation suite written as Ballerina tests. The agent looks up a customer's account, checks for a known outage in their area, and opens a support ticket only when there is no outage. The evaluation runs the agent against a dataset of conversation threads (`tests/resources/evalsets/broadband_support.evalset.json`), checks each run's tool calls and answer with rule-based checks and a judge model, and fails if the average pass rate over three runs falls below 80%. Deterministic tests of the tools, the checks, and the dataset run without a model API key.

This sample accompanies the [Evaluate agent behavior](https://ballerina.io/learn/evaluate-agent-behavior/) guide.

## Prerequisites

- Ballerina 2201.13.2 (Swan Lake Update 13) or later. The `runs` and `minPassRate` fields of `@test:Config` are not available in earlier updates.
- An OpenAI API key, to run the service and the live evaluation. The deterministic tests do not need one.

## Configure

Copy `Config.toml.example` to `Config.toml` and set your key.

```toml
openAiApiKey = "<YOUR_OPENAI_API_KEY>"
```

Optional configurables: `maxIterations` (default `5`) and `port` (default `8080`).

`tests/Config.toml` holds a placeholder key (`test-key`) and sets the service port to `9187` while tests run.

## Run

```
$ bal run
```

## Sample requests

```
$ curl -X POST http://localhost:8080/support/chat \
    -H "Content-Type: application/json" \
    -d '{"sessionId": "s1", "message": "My internet has been down since this morning. My account is A-100."}'
{"reply":"There is currently a known outage in your area. It is expected to be resolved by today 18:00, so no technician visit is needed."}
```

An empty message is rejected without calling the model.

```
$ curl -i -X POST http://localhost:8080/support/chat \
    -H "Content-Type: application/json" \
    -d '{"sessionId": "s1", "message": " "}'
HTTP/1.1 400 Bad Request
...
message must not be empty
```

## Run the tests and the evaluation

Run the deterministic tests (no API key needed). The `live-eval` group is the model-based evaluation, so it is left out.

```
$ bal test --disable-groups live-eval
```

Run the live evaluation. The environment variable overrides the placeholder key in `tests/Config.toml`.

```
$ export BAL_CONFIG_VAR_OPENAIAPIKEY=<YOUR_OPENAI_API_KEY>
$ bal test --groups live-eval
```

Add `--test-report` to write the results, including the `evaluationSummary` with the target and observed pass rates, to `target/report/test_results.json`.

```
$ bal test --groups live-eval --test-report
```
