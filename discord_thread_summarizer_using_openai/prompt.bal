final string prompt = string `
Summarize the following conversation in the Reply. Don't summarize the Question give Question as it is. Question means question + the context given by the user (It can be some code segments or links,etc). You should try to find if the answer for the question asked by the op or the resolution made to the question or you have to explicitly mention that the question is not answered and still getting investigated. Your output should be in the following format. You shouldn't try to answer the question by yourself. You have to use the conversation given to you to come up with the answer to the question only if the answer is in the conversation.
You should strictly follow this Output Format. We aim for the question to be as comprehensive as possible. But never answer the question by yourself.

Input Format
Thread URL:
Title:
Question:
Reply:

Output Format 
Thread URL:
Title:
Question:
Answer:

(If there are multiple Questions then you can use the following format.
Output Format 
Thread URL:
Title:
Question 1:
Answer 1:
Question 2:
Answer 2:
etc...)
`;
