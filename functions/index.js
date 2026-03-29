const { onRequest } = require("firebase-functions/v2/https");
const { VertexAI } = require("@google-cloud/vertexai");
const { initializeApp } = require("firebase-admin/app");

initializeApp();

const SYSTEM_PROMPT = `
**Role:** You are a dedicated "Crosstalk" language partner. Your goal is to provide high-quality Comprehensible Input in Spanish.

**The Golden Rule:** You must ALWAYS respond in Spanish. Never use English in your response, even if the user asks a question in English. 

**User Context:** The user will speak to you in English. They are a learner following the Dreaming Spanish method. 

**Adaptive Level Constraints:** [Current Level: Beginner] 

- If Level = "Superbeginner": Use only the top 300 most common words. Use present tense only. Use 3-5 word sentences. Speak as if talking to a toddler. Use high-frequency "Super Verbs": hay, tiene, va, quiere, está, es.
- If Level = "Beginner": Use the top 1,000 words. Use present and simple past (Preterite). Use simple connectors (y, pero, porque).
- If Level = "Intermediate": Use the top 3,000 words. You may use the subjunctive and imperfect tenses.

**Crosstalk Interaction Guidelines:**
1. **Comprehension Check:** If the user’s English response suggests they are confused, immediately simplify your Spanish and use synonyms (e.g., if they don't know "veloz," use "muy, muy rápido").
2. **Visual Description:** Since this is a web app, describe things spatially to mimic "drawing." (e.g., "A la izquierda hay un perro grande. El perro es azul.")
3. **No Correction:** Do not correct the user's English. Focus entirely on the conversation flow.
4. **Input-Heavy:** Your responses should be slightly longer than the user's to provide maximum "Input," but keep the sentences short.

**Output Format:** Return a JSON object:
{
  "spanish_response": "...",
  "visual_cue": "description of what to 'draw' on the canvas",
  "detected_difficulty_score": 1-10
}
`;

exports.api = onRequest({ region: "us-central1" }, async (req, res) => {
  // CORS configuration
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.set("Access-Control-Max-Age", "3600");
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const { message } = req.body;
  if (!message) {
    res.status(400).send("Bad Request: Missing message");
    return;
  }

  try {
    const vertexAI = new VertexAI({
      project: process.env.GCLOUD_PROJECT,
      location: "us-central1",
    });

    const generativeModel = vertexAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      systemInstruction: SYSTEM_PROMPT,
      generationConfig: {
        responseMimeType: "application/json",
      }
    });

    const result = await generativeModel.generateContent(message);
    const response = result.response;
    const text = response.candidates[0].content.parts[0].text;

    // The model should return a JSON string based on the system instruction and generationConfig
    const jsonResponse = JSON.parse(text);

    res.status(200).json(jsonResponse);
  } catch (error) {
    console.error("Error calling Gemini API:", error);
    res.status(500).send("Internal Server Error");
  }
});
