# Add human approval and durable execution

An online store uses an AI refund assistant that reads a support ticket, looks up the order, and proposes a refund. The assistant is a `workflow:DurableAgent` from `ballerina/workflow`: every model call and tool call runs as a durable activity, the `issueRefund` tool waits for a `SUPPORT_LEAD` to approve, edit, or reject the refund through the workflow management API, a failed payment gateway call creates a review task for `PAYMENTS_OPS`, and an idempotency key ensures that each order is refunded at most once. The order system and payment gateway are simulated in memory.

For a step-by-step walkthrough, see the guide [Add human approval and durable execution](https://ballerina.io/learn/add-human-approval-and-durable-execution/).

## Prerequisites

- Ballerina 2201.14.0 (Swan Lake Update 14) or later
- An OpenAI API key
- Optional: the [Temporal CLI](https://docs.temporal.io/cli), to run the agent on a durable engine

## Configure

Copy `Config.toml.example` to `Config.toml` and set your OpenAI API key.

```
$ cp Config.toml.example Config.toml
```

The example uses the in-memory engine (`mode = "IN_MEMORY"`), which does not survive a restart. To run on Temporal, start `temporal server start-dev` and set `mode = "LOCAL"` and `taskQueue = "REFUND_APPROVAL_QUEUE"` under `[ballerina.workflow]`.

> **Note:** `enableBasicAuth = false` leaves the management API unauthenticated. Use it only on your own machine.

## Run

```
$ bal run
```

The refund service listens on `http://localhost:8080/refunds` and the management API on `http://localhost:8234/workflow`.

## Try it

1. Submit a refund request.

    ```
    $ curl -X POST http://localhost:8080/refunds \
           -H 'Content-Type: application/json' \
           -d '{"ticketId": "TKT-5001", "orderId": "ORD-1001", "customerMessage": "My headphones from order ORD-1001 arrived with a broken ear cup. I would like 40 USD back."}'
    ```

2. Check the request.

    ```
    $ curl http://localhost:8080/refunds/TKT-5001
    ```

3. List pending approvals as a support lead, and inspect one.

    ```
    $ curl 'http://localhost:8234/workflow/review-activities?status=PENDING' -H 'x-user-roles: SUPPORT_LEAD'
    $ curl http://localhost:8234/workflow/review-activities/<taskId> -H 'x-user-roles: SUPPORT_LEAD'
    ```

4. Decide: approve, approve with a different amount, or reject.

    ```
    $ curl -X POST http://localhost:8234/workflow/review-activities/<taskId>/proceed \
           -H 'x-user-id: maya' -H 'x-user-roles: SUPPORT_LEAD'

    $ curl -X POST http://localhost:8234/workflow/review-activities/<taskId>/proceed-with-input \
           -H 'Content-Type: application/json' -H 'x-user-id: maya' -H 'x-user-roles: SUPPORT_LEAD' \
           -d '{"input": {"orderId": "ORD-1001", "amount": 35.0, "reason": "Damaged ear cup"}}'

    $ curl -X POST http://localhost:8234/workflow/review-activities/<taskId>/reject \
           -H 'Content-Type: application/json' -H 'x-user-id: maya' -H 'x-user-roles: SUPPORT_LEAD' \
           -d '{"feedback": "Duplicate of TKT-4999"}'
    ```

5. Check the request again to see the agent's final answer. Submitting the same ticket again returns `409 Conflict`.

    ```
    $ curl http://localhost:8080/refunds/TKT-5001
    ```

To try the payment failure review, add `gatewayFailuresBeforeSuccess = 1` to `Config.toml`, restart, submit a new ticket, and approve it. A review task is then created for the `PAYMENTS_OPS` role:

```
$ curl 'http://localhost:8234/workflow/review-activities?status=PENDING' -H 'x-user-roles: PAYMENTS_OPS'
$ curl -X POST http://localhost:8234/workflow/review-activities/<taskId>/proceed \
       -H 'x-user-id: omar' -H 'x-user-roles: PAYMENTS_OPS'
```

## Test

The tests cover the deterministic logic (the refund policy and the idempotent payment call) and do not call the model. `tests/Config.toml` provides a placeholder API key and the in-memory engine.

```
$ bal test
```
