import ballerina/ai;
import ballerina/log;
import ballerinax/ai.openai;

configurable string openAiApiKey = ?;
configurable string[] policyFiles = [
    "policies/leave-policy.md",
    "policies/remote-work-policy.md",
    "policies/expense-policy.md"
];
configurable int maxChunkSize = 400;
configurable int maxOverlapSize = 40;
configurable boolean ingestOnStartup = true;

final ai:EmbeddingProvider embeddingProvider =
        check new openai:EmbeddingProvider(openAiApiKey, openai:TEXT_EMBEDDING_3_SMALL);

final ai:VectorStore vectorStore = check new ai:InMemoryVectorStore();

// Documents are chunked explicitly in `chunkPolicy`, so chunking is disabled in the knowledge base.
final ai:KnowledgeBase knowledgeBase = new ai:VectorKnowledgeBase(vectorStore, embeddingProvider, ai:DISABLE);

function init() returns error? {
    if ingestOnStartup {
        check ingestPolicies(policyFiles);
    }
}

# Loads, chunks, embeds, and stores the policy documents.
#
# + paths - The paths of the policy documents
# + return - An error if any step of the ingestion fails
function ingestPolicies(string[] paths) returns error? {
    ai:DataLoader loader = check new ai:TextDataLoader(...paths);
    ai:Document|ai:Document[] loaded = check loader.load();
    ai:Document[] documents = loaded is ai:Document[] ? loaded : [loaded];

    ai:Chunk[] chunks = [];
    foreach ai:Document document in documents {
        chunks.push(...check chunkPolicy(document));
    }

    check knowledgeBase.ingest(chunks);
    log:printInfo("Ingested policy documents", documents = documents.length(), chunks = chunks.length());
}

# Splits a policy document into chunks and adds source metadata to each chunk.
#
# + document - A policy document loaded from a Markdown file
# + return - The chunks of the document, or an error if the document cannot be chunked
isolated function chunkPolicy(ai:Document document) returns ai:Chunk[]|error {
    if document !is ai:TextDocument {
        return error("only text documents are supported");
    }
    string title = documentTitle(document.content) ?: document.metadata?.fileName ?: "Untitled";
    ai:Chunker chunker = new ai:MarkdownChunker(maxChunkSize, maxOverlapSize);

    ai:Chunk[] chunks = [];
    string? currentSection = ();
    foreach ai:Chunk chunk in check chunker.chunk(document) {
        anydata content = chunk.content;
        string[] sections = content is string ? chunkSections(content, currentSection) : [];
        if sections.length() > 0 {
            currentSection = sections[sections.length() - 1];
        }
        chunks.push(withSourceMetadata(chunk, title, sections));
    }
    return chunks;
}

# Returns the sections that a chunk belongs to.
# A chunk that does not start with a heading continues the section of the previous chunk.
#
# + content - The text of the chunk
# + currentSection - The last section of the previous chunk, if any
# + return - The section headings, in the order they appear
isolated function chunkSections(string content, string? currentSection) returns string[] {
    string[] sections = sectionHeadings(content);
    if currentSection is string && !content.trim().startsWith("#") && sections.indexOf(currentSection) is () {
        sections.unshift(currentSection);
    }
    return sections;
}

# Adds the document title and the section headings to the metadata of a chunk.
#
# + chunk - The chunk produced by the chunker
# + title - The title of the document that the chunk belongs to
# + sections - The sections that the chunk belongs to
# + return - A copy of the chunk with the source metadata
isolated function withSourceMetadata(ai:Chunk chunk, string title, string[] sections) returns ai:Chunk {
    ai:Metadata metadata = (chunk.metadata ?: {}).clone();
    metadata["documentTitle"] = title;
    metadata["sections"] = sections;
    ai:Chunk result = chunk.clone();
    result.metadata = metadata;
    return result;
}

# Returns the text of the first level-1 Markdown heading.
#
# + content - Markdown content
# + return - The title, or `()` if the content has no level-1 heading
isolated function documentTitle(string content) returns string? {
    foreach string line in re `\n`.split(content) {
        if line.startsWith("# ") {
            return line.substring(2).trim();
        }
    }
    return ();
}

# Returns the level-2 Markdown headings that are followed by text in the content.
# A heading at the end of a chunk without any text after it is ignored.
#
# + content - Markdown content
# + return - The section headings, in the order they appear
isolated function sectionHeadings(string content) returns string[] {
    string[] sections = [];
    string? heading = ();
    foreach string line in re `\n`.split(content) {
        if line.startsWith("## ") {
            heading = line.substring(3).trim();
        } else if heading is string && line.trim().length() > 0 {
            sections.push(heading);
            heading = ();
        }
    }
    return sections;
}
