import { genkit, z } from 'genkit';
import { googleAI } from '@genkit-ai/googleai';
import { onCall } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';

initializeApp();

const ai = genkit({
  plugins: [googleAI()],
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

const chatFlow = ai.defineFlow(
  {
    name: 'chatFlow',
    inputSchema: z.object({
      message: z.string(),
      level: z.string(),
      history: z.array(z.object({
        role: z.string(),
        text: z.string()
      })).default([])
    }),
    outputSchema: z.object({
      text: z.string(),
      svg_draw: z.string()
    }),
  },
  async (input) => {
    // Construct the conversational memory
    const messages: any[] = [
      { role: 'system', content: [{ text: systemPrompt }] }
    ];

    // Append history
    for (const msg of input.history) {
      messages.push({ role: msg.role, content: [{ text: msg.text }] });
    }

    // Append the new message
    messages.push({ role: 'user', content: [{ text: input.message }] });

    // Call Gemini via Genkit with the new Google AI plugin
    const { output } = await ai.generate({
      model: 'googleai/gemini-2.0-flash-lite-preview-02-05',
      messages: messages,
      output: {
        schema: z.object({
          text: z.string(),
          svg_draw: z.string()
        })
      }
    });

    if (!output) {
      throw new Error("No output generated");
    }

    return output;
  }
);

export const chat = onCall({
    cors: true,
    region: 'us-central1'
}, async (request) => {
    return await chatFlow(request.data);
});
