import ballerina/ai;
import ballerina/http;
import ballerina/test;

final SourceExcerpt[] & readonly sampleExcerpts = [
    {
        id: "S1",
        document: "leave-policy.md",
        title: "Leave policy",
        sections: ["Carry forward"],
        content: "Employees can carry forward up to 5 unused annual leave days."
    },
    {
        id: "S2",
        document: "leave-policy.md",
        title: "Leave policy",
        sections: ["Annual leave"],
        content: "Full-time employees receive 20 days of paid annual leave."
    }
];

@test:Config
function testQuestionValidation() returns error? {
    test:assertEquals(check validateQuestion("  How many leave days do I get?  "), "How many leave days do I get?");
    test:assertTrue(validateQuestion("   ") is error);
    test:assertTrue(validateQuestion("".padStart(MAX_QUESTION_LENGTH + 1, "a")) is error);
}

@test:Config
function testLowScoringMatchesAreDropped() {
    ai:QueryMatch[] matches = [
        {
            chunk: <ai:TextChunk>{
                content: "## Carry forward\n\nEmployees can carry forward up to 5 days.",
                metadata: {fileName: "leave-policy.md", "documentTitle": "Leave policy", "sections": ["Carry forward"]}
            },
            similarityScore: 0.62
        },
        {
            chunk: <ai:TextChunk>{content: "## Meals\n\nUp to USD 60 per day.", metadata: {fileName: "expense-policy.md"}},
            similarityScore: 0.12
        }
    ];
    SourceExcerpt[] excerpts = selectExcerpts(matches, 0.3);
    test:assertEquals(excerpts.length(), 1);
    test:assertEquals(excerpts[0].id, "S1");
    test:assertEquals(excerpts[0].title, "Leave policy");
    test:assertEquals(excerpts[0].sections, ["Carry forward"]);
}

@test:Config
function testMissingMetadataFallsBack() {
    ai:QueryMatch[] matches = [{chunk: <ai:TextChunk>{content: "Some text."}, similarityScore: 0.9}];
    SourceExcerpt[] excerpts = selectExcerpts(matches, 0.3);
    test:assertEquals(excerpts[0].document, "unknown");
    test:assertEquals(excerpts[0].title, "unknown");
    test:assertEquals(excerpts[0].sections, []);
}

@test:Config
function testCitationsAreResolved() returns error? {
    PolicyAnswer answer = check resolveSources(
            {answer: "You can carry forward up to 5 days.", answerFound: true, sourceIds: ["S1", "S1"]},
            sampleExcerpts);
    test:assertEquals(answer.sources, [{document: "leave-policy.md", title: "Leave policy", sections: ["Carry forward"]}]);
}

@test:Config
function testUnknownCitationIsRejected() {
    test:assertTrue(resolveSources({answer: "Yes.", answerFound: true, sourceIds: ["S9"]}, sampleExcerpts) is error);
}

@test:Config
function testAnswerWithoutCitationIsRejected() {
    test:assertTrue(resolveSources({answer: "Yes.", answerFound: true, sourceIds: []}, sampleExcerpts) is error);
}

@test:Config
function testNotFoundAnswerHasNoSources() returns error? {
    PolicyAnswer answer = check resolveSources({answer: "", answerFound: false, sourceIds: ["S1"]}, sampleExcerpts);
    test:assertEquals(answer, {answer: NO_ANSWER, answerFound: false, sources: []});
}

@test:Config
function testBlankQuestionIsRejectedByService() returns error? {
    http:Client hrClient = check new ("http://localhost:9611/hr");
    http:Response response = check hrClient->post("/ask", {question: " "});
    test:assertEquals(response.statusCode, 400);
}
