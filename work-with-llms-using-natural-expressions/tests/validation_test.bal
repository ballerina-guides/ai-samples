import ballerina/test;

@test:Config
function testValidAttractionsPass() returns error? {
    Attraction[] attractions = [
        {name: "Arugam Bay", city: "Pottuvil", highlight: "Sri Lanka's best-known surf point."}
    ];
    test:assertEquals(check validateAttractions(attractions, 3), attractions);
}

@test:Config
function testEmptyFieldIsRejected() {
    Attraction[] attractions = [{name: "", city: "Galle", highlight: "Historic fort."}];
    test:assertTrue(validateAttractions(attractions, 3) is error);
}

@test:Config
function testEmptyResponseIsRejected() {
    test:assertTrue(validateAttractions([], 3) is error);
}

@test:Config
function testExtraAttractionsAreTrimmed() returns error? {
    Attraction[] attractions = [
        {name: "A", city: "X", highlight: "One."},
        {name: "B", city: "Y", highlight: "Two."}
    ];
    test:assertEquals((check validateAttractions(attractions, 1)).length(), 1);
}
