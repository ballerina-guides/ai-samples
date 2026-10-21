import ballerina/ai;
import ballerina/test;
import ballerinax/ai.openai;

@test:Config
function testExpectedToolCallsPass() {
    ai:FunctionCall[] expected = [
        {name: "getAccount", arguments: {accountId: "A-100"}},
        {name: "getOutageStatus", arguments: {postcode: "10350"}}
    ];
    ai:FunctionCall[] actual = [
        {name: "getAccount", arguments: {accountId: "A-100"}, id: "call_1"},
        {name: "getAccount", arguments: {accountId: "A-100"}, id: "call_2"},
        {name: "getOutageStatus", arguments: {postcode: "10350"}, id: "call_3"}
    ];
    test:assertEquals(checkToolCalls(expected, actual), []);
}

@test:Config
function testMissingToolCallIsReported() {
    ai:FunctionCall[] expected = [{name: "getOutageStatus", arguments: {postcode: "10350"}}];
    ai:FunctionCall[] actual = [{name: "getOutageStatus", arguments: {postcode: "20400"}}];
    test:assertEquals(checkToolCalls(expected, actual),
            ["missing tool call: getOutageStatus({\"postcode\":\"10350\"})"]);
}

@test:Config
function testUnexpectedSideEffectIsReported() {
    ai:FunctionCall[] expected = [{name: "getAccount", arguments: {accountId: "A-100"}}];
    ai:FunctionCall[] actual = [
        {name: "getAccount", arguments: {accountId: "A-100"}},
        {name: "openSupportTicket", arguments: {accountId: "A-100", summary: "No connection"}}
    ];
    test:assertEquals(checkToolCalls(expected, actual),
            ["unexpected call to side-effecting tool: openSupportTicket"]);
}

@test:Config
function testFreeTextArgumentsAreIgnored() {
    ai:FunctionCall[] expected = [{name: "openSupportTicket", arguments: {accountId: "A-200"}}];
    ai:FunctionCall[] actual = [
        {name: "openSupportTicket", arguments: {accountId: "A-200", summary: "Connection drops often"}}
    ];
    test:assertEquals(checkToolCalls(expected, actual), []);
}

@test:Config
function testContactDetailsAreDetected() {
    test:assertEquals(checkNoContactDetails("Your email is sara.fernando@example.com."),
            ["answer contains an email address"]);
    test:assertEquals(checkNoContactDetails("You are on the Fibre 100 plan."), []);
}

@test:Config
function testEvalsetIsValid() returns error? {
    map<[readonly & ai:ConversationThread]> threads = check supportThreads();
    test:assertEquals(threads.length(), 5);
    string[] agentTools = ["getAccount", "getOutageStatus", "openSupportTicket"];
    foreach [readonly & ai:ConversationThread] [thread] in threads {
        test:assertTrue(thread.traces.length() > 0, thread.id);
        foreach ai:Trace trace in thread.traces {
            _ = check answerOf(trace);
            foreach ai:FunctionCall call in trace.toolCalls ?: [] {
                test:assertTrue(agentTools.indexOf(call.name) != (), string `${trace.id}: unknown tool ${call.name}`);
            }
        }
    }
}

@test:Config
function testRulesOnScriptedAgentRun() returns error? {
    // The scripted responses make the agent open a ticket although there is an outage.
    ai:ChatAssistantMessage[] responses = [
        {role: ai:ASSISTANT, toolCalls: [{name: "getAccount", arguments: {accountId: "A-100"}, id: "call_1"}]},
        {role: ai:ASSISTANT, toolCalls: [{name: "getOutageStatus", arguments: {postcode: "10350"}, id: "call_2"}]},
        {
            role: ai:ASSISTANT,
            toolCalls: [{name: "openSupportTicket", arguments: {accountId: "A-100", summary: "No connection"}, id: "call_3"}]
        },
        {role: ai:ASSISTANT, content: "I opened ticket TCK-1001 for you."}
    ];
    // A mock model provider returns the scripted responses, so the run needs no API key.
    openai:ModelProvider scriptedModel = test:mock(openai:ModelProvider);
    test:prepare(scriptedModel).when("chat").thenReturnSequence(...responses);

    ai:Agent agent = check createSupportAgent(scriptedModel);
    ai:Trace trace = check agent.run("My internet is down. My account is A-100.");

    test:assertEquals(check answerOf(trace), "I opened ticket TCK-1001 for you.");
    ai:FunctionCall[] expected = [
        {name: "getAccount", arguments: {accountId: "A-100"}},
        {name: "getOutageStatus", arguments: {postcode: "10350"}}
    ];
    test:assertEquals(checkToolCalls(expected, trace.toolCalls ?: []),
            ["unexpected call to side-effecting tool: openSupportTicket"]);
}
