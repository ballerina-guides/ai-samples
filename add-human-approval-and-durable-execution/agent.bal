import ballerina/ai;
import ballerina/workflow;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;

final ai:ModelProvider model = check new openai:ModelProvider(openAiApiKey, openai:GPT_4O);

final workflow:DurableAgent refundAgent = check new ({
    systemPrompt: {
        role: "Refund assistant",
        instructions: string `You handle refund requests from customers of an online store.
            Look up the order with getOrder before you decide anything.
            If the request is reasonable, call issueRefund once with the amount to refund and a short reason.
            If issueRefund returns status REJECTED, or a reviewer rejects the call, do not try again;
            explain why the refund was not issued.
            After a refund is issued, call notifyCustomer with a short, polite message.
            Never promise a refund to the customer before issueRefund returns status ISSUED.`
    },
    model: model,
    inputType: RefundRequest,
    activities: [
        {
            activity: getOrder,
            description: "Returns an order, including its status, total, and the amount already refunded."
        },
        {
            activity: issueRefund,
            description: "Refunds an amount to the customer's original payment method. " +
                "Returns status ISSUED with a refund ID, or status REJECTED with the reason.",
            // Every refund waits for a support lead before the payment is made.
            approvalPolicy: {
                userRoles: "SUPPORT_LEAD",
                title: "Approve refund",
                description: "The refund assistant proposes a refund. Approve, edit the amount, or reject."
            },
            // If the payment gateway call fails, payments operations decide whether to rerun it.
            retryPolicy: {userRoles: "PAYMENTS_OPS"}
        },
        {
            activity: notifyCustomer,
            description: "Sends a short message to the customer.",
            retryPolicy: {maxRetries: 5, retryDelay: 2}
        }
    ],
    maxIter: 8
});
