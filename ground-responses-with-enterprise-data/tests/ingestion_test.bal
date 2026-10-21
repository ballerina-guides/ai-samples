import ballerina/ai;
import ballerina/test;

@test:Config
function testChunksCarrySourceMetadata() returns error? {
    ai:DataLoader loader = check new ai:TextDataLoader("policies/leave-policy.md");
    ai:Document|ai:Document[] loaded = check loader.load();
    test:assertTrue(loaded is ai:Document);

    ai:Chunk[] chunks = check chunkPolicy(<ai:Document>loaded);
    test:assertTrue(chunks.length() > 1);
    foreach ai:Chunk chunk in chunks {
        ai:Metadata metadata = chunk.metadata ?: {};
        test:assertEquals(metadata.fileName, "leave-policy.md");
        test:assertEquals(metadata["documentTitle"], "Leave policy");
        test:assertTrue(toStrings(metadata["sections"]).length() > 0);
    }
}

@test:Config
function testHeadingsAreExtracted() {
    string content = "# Leave policy\n\n## Annual leave\n\nText.\n\n## Sick leave\n\nMore text.\n\n## Carry forward\n";
    test:assertEquals(documentTitle(content), "Leave policy");
    // "Carry forward" has no text in this chunk, so it is not a section of the chunk.
    test:assertEquals(sectionHeadings(content), ["Annual leave", "Sick leave"]);
    test:assertEquals(documentTitle("No heading"), ());
}

@test:Config
function testContinuationChunkKeepsSection() {
    test:assertEquals(chunkSections("cannot be carried forward.", "Sick leave"), ["Sick leave"]);
    test:assertEquals(chunkSections("\n## Meals\n\nUp to USD 60.", "Submitting claims"), ["Meals"]);
    test:assertEquals(chunkSections("Text without a heading.", ()), []);
}
