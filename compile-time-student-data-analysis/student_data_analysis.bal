import ballerina/io;

public type Student record {|
    string id;
    decimal gpa;
|};

final Student[] students = const natural {
    Generate 10 university students with:
    1. Student IDs: STU001 to STU010
    2. GPAs between 2.5-4.0
};

function findTopStudents(Student[] students, int count) returns Student[] = @natural:code {
    prompt: string `Find the top ${count} students based on GPA.
    Return them sorted by GPA in descending order.
    Student data: ${students}`
} external;

public function main() {
    io:println("=== All Students ===");
    foreach Student student in students {
        io:println(string `${student.id}: GPA: ${student.gpa})`);
    }
    io:println("\n");
    
    io:println("=== Top 3 Students ===");
    Student[] topStudents = findTopStudents(students, 3);
    foreach int i in 0..<topStudents.length() {
        Student student = topStudents[i];
        io:println(string `${i + 1} - GPA: ${student.gpa}`);
    }
}
