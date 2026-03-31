"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.chat = void 0;
const genkit_1 = require("genkit");
const google_genai_1 = require("@genkit-ai/google-genai");
const https_1 = require("firebase-functions/v2/https");
const app_1 = require("firebase-admin/app");
(0, app_1.initializeApp)();
const ai = (0, genkit_1.genkit)({
    plugins: [(0, google_genai_1.googleAI)()],
});
const systemPrompt = `
ROLE: Spanish Crosstalk Partner.
CONSTRAINTS: 
- Always respond in Spanish. Never use English.
- User speaks English.
- Adapt vocab frequency based on Level (Superbeginner, Beginner, Intermediate).

VISUAL DRAWING RULES:
- You are drawing on a 100x100 canvas.
- The "svg_draw" field should contain ONLY the inner SVG elements (paths, circles, rects, etc.). 
- Use colors (fill, stroke) to make the drawings clear and engaging.
- Always correlate the drawing with your Spanish text.

SPECIAL INTERACTION:
- If the user says "[SIMPLIFY]" or expresses confusion, immediately simplify your Spanish and make your drawing even more basic and explicit.
`;
const chatFlow = ai.defineFlow({
    name: 'chatFlow',
    inputSchema: genkit_1.z.object({
        message: genkit_1.z.string(),
        level: genkit_1.z.string(),
        history: genkit_1.z.array(genkit_1.z.object({
            role: genkit_1.z.string(),
            text: genkit_1.z.string()
        })).default([])
    }),
    outputSchema: genkit_1.z.object({
        text: genkit_1.z.string(),
        svg_draw: genkit_1.z.string()
    }),
}, async (input) => {
    // Construct the conversational memory
    const messages = [
        { role: 'system', content: [{ text: systemPrompt }] }
    ];
    // Append history
    for (const msg of input.history) {
        messages.push({ role: msg.role, content: [{ text: msg.text }] });
    }
    // Append the new message
    messages.push({ role: 'user', content: [{ text: input.message }] });
    // Call Gemini via Genkit with the new Google Gen AI plugin
    const { output } = await ai.generate({
        model: 'googleai/gemini-2.0-flash-lite-preview-02-05',
        messages: messages,
        output: {
            schema: genkit_1.z.object({
                text: genkit_1.z.string(),
                svg_draw: genkit_1.z.string()
            })
        }
    });
    if (!output) {
        throw new Error("No output generated");
    }
    return output;
});
exports.chat = (0, https_1.onCall)({
    cors: true,
    region: 'us-central1'
}, async (request) => {
    return await chatFlow(request.data);
});
//# sourceMappingURL=index.js.map