# Observe and secure AI integrations

A claims assistant for an insurance company, built as an HTTP service in front of a Ballerina `ai:Agent`. The service validates the caller's JWT and scope, redacts email addresses, card numbers, and phone numbers before the message reaches the model, binds the tools to the authenticated policyholder through an `ai:Context`, gives each tool its own least-privilege credential, and returns only the claim fields that the model needs. Every model call and tool call is traced over OpenTelemetry (OTLP), so you can inspect latency and token usage in Jaeger. A mock claims API in the same package lets the sample run without external systems.

This sample accompanies the guide [Observe and secure AI integrations](https://ballerina.io/learn/observe-and-secure-ai-integrations/).

## Prerequisites

- Ballerina 2201.14.0 (Swan Lake Update 14) or later
- An OpenAI API key
- A tracing backend that accepts OTLP/gRPC on port `4317`, such as Jaeger:

  ```
  $ docker run -d --name jaeger -p 16686:16686 -p 4317:4317 jaegertracing/all-in-one:latest
  ```

- OpenSSL, to sign a test token

## Configure

Copy `Config.toml.example` to `Config.toml` and set your OpenAI API key. The mock claims API accepts whatever tool tokens you configure, so any values work for `claimsReadToken` and `callbackWriteToken`, as long as they are different.

The test key pair in `tests/resources` is used to validate tokens locally. To create a new one:

```
$ openssl req -x509 -newkey rsa:2048 -nodes -keyout tests/resources/private.key \
    -out tests/resources/public.crt -days 365 -subj "/CN=test-idp"
```

## Run

```
$ bal run
```

The assistant listens on port `8080` and the mock claims API on port `9090`.

## Try it

Create a token for the policyholder `PH-001` with the `claims:assist` scope, valid for 10 minutes:

```
$ b64() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
$ HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | b64)
$ PAYLOAD=$(printf '{"iss":"https://idp.example.com","aud":"claims-assistant","sub":"PH-001","scope":"claims:assist","exp":%d}' $(( $(date +%s) + 600 )) | b64)
$ SIGNATURE=$(printf '%s.%s' "$HEADER" "$PAYLOAD" | openssl dgst -sha256 -sign tests/resources/private.key | b64)
$ TOKEN="$HEADER.$PAYLOAD.$SIGNATURE"
```

Ask about a claim (the email address is redacted before the message is sent to the model):

```
$ curl -i -X POST http://localhost:8080/assistant/chat \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d '{"sessionId": "s1", "message": "What is the status of CLM-10234? My email is alex@example.com"}'
```

Ask about a claim that belongs to another policyholder (the model reports that it was not found):

```
$ curl -X POST http://localhost:8080/assistant/chat \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d '{"sessionId": "s1", "message": "And what about CLM-20871?"}'
```

Send a request without a token (rejected with `401 Unauthorized` before the model is called):

```
$ curl -i -X POST http://localhost:8080/assistant/chat \
    -H "Content-Type: application/json" -d '{"sessionId": "s1", "message": "Hi"}'
```

## View the traces

Open the Jaeger UI at http://localhost:16686, select the `/assistant` service, and open the trace of the first request:

- `invoke_agent Claims Assistant` has the redacted message (`[EMAIL]`) in `gen_ai.input.messages`.
- Each `chat gpt-4o` span has `gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens`, and its duration is the latency of that model call.
- `execute_tool getClaimStatus` has the tool arguments and the `ClaimSummary` result, without the bank account or adjuster notes.
- `post /chat` has the `claims.redacted_values` attribute set to `1`.

## Test

The tests cover authentication, scope checks, request validation, redaction, data minimization, per-tool credentials, and model-failure detection. They do not call the model, so no API key is needed.

```
$ bal test
```
