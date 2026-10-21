import ballerina/http;
import ballerina/log;
import ballerina/workflow;
import ballerina/workflow.management.rest as _;

service /refunds on new http:Listener(8080) {

    # Starts a refund agent run for a ticket and returns without waiting for the result.
    #
    # + request - The refund request
    # + return - The instance ID of the run, or an error status
    resource function post .(RefundRequest request)
            returns http:Accepted|http:Conflict|http:InternalServerError {
        // The ticket ID is the instance ID: a retried submit joins the running instance
        // instead of starting a second one, and a closed ticket is not processed again.
        string|error instanceId = refundAgent.runWithId(request.ticketId, request.customerMessage, request,
                ifRunning = workflow:USE_EXISTING, ifClosed = workflow:REJECT_DUPLICATE);
        if instanceId is workflow:InstanceAlreadyExistsError {
            return <http:Conflict>{body: string `Ticket ${request.ticketId} was already processed`};
        }
        if instanceId is error {
            log:printError("Failed to start the refund agent", instanceId);
            return <http:InternalServerError>{body: "Could not start the refund request"};
        }
        return <http:Accepted>{body: <RefundStatus>{instanceId, status: "IN_PROGRESS"}};
    }

    # Returns the outcome of a run, or its status while it is still in progress.
    #
    # + instanceId - The instance ID returned when the request was submitted
    # + return - The refund outcome, or a status
    resource function get [string instanceId]() returns RefundStatus|http:Accepted|http:NotFound {
        string|error summary = refundAgent.getResult(instanceId);
        if summary is workflow:WorkflowInProgressError {
            // Still working, or waiting for a person to decide.
            return <http:Accepted>{body: <RefundStatus>{instanceId, status: "IN_PROGRESS"}};
        }
        if summary is workflow:InstanceNotFoundError {
            return <http:NotFound>{body: <RefundStatus>{instanceId, status: "NOT_FOUND"}};
        }
        if summary is error {
            log:printError("Refund agent run did not complete", summary, instanceId = instanceId);
            return {instanceId, status: "FAILED"};
        }
        return {instanceId, status: "COMPLETED", summary};
    }
}
