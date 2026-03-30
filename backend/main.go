package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"google.golang.org/genai"
)

const SystemPrompt = `
ROLE: Spanish Crosstalk Partner.
CONSTRAINTS: 
- Always respond in Spanish. Never use English.
- User speaks English.
- Adapt vocab frequency based on Level (Superbeginner, Beginner, Intermediate).
- Output Format: Strict JSON { "text": "...", "svg_draw": "..." }

VISUAL DRAWING RULES:
- You are drawing on a 100x100 canvas.
- The "svg_draw" field should contain ONLY the inner SVG elements (paths, circles, rects, etc.). 
- Use colors (fill, stroke) to make the drawings clear and engaging.
- Always correlate the drawing with your Spanish text.

SPECIAL INTERACTION:
- If the user says "[SIMPLIFY]" or expresses confusion, immediately simplify your Spanish and make your drawing even more basic and explicit.
`

type ChatRequest struct {
	Message string `json:"message"`
	Level   string `json:"level"`
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8888"
	}

	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	location := "us-central1"
	apiKey := os.Getenv("GEMINI_API_KEY")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		fmt.Fprint(w, "Crosstalk AI Backend is running (New Gen AI SDK)!")
	})

	http.HandleFunc("/api/chat", func(w http.ResponseWriter, r *http.Request) {
		enableCORS(&w)
		if r.Method == "OPTIONS" {
			return
		}

		if r.Method != "POST" {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}

		var req ChatRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
		}

		ctx := context.Background()
		var client *genai.Client
		var err error

		// Configuration logic updated to fix "mutually exclusive" error
		if apiKey != "" {
			log.Println("Using API Key for authentication (Google AI Backend)")
			client, err = genai.NewClient(ctx, &genai.ClientConfig{
				APIKey: apiKey,
			})
		} else {
			log.Println("Using Vertex AI (IAM) for authentication")
			client, err = genai.NewClient(ctx, &genai.ClientConfig{
				Project:  projectID,
				Location: location,
				Backend:  genai.BackendVertexAI,
			})
		}

		if err != nil {
			log.Printf("error creating client: %v", err)
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}

		model := "gemini-2.0-flash-lite-preview-02-05"
		
		// Setup generation configuration
		genConfig := &genai.GenerateContentConfig{
			SystemInstruction: &genai.Content{
				Parts: []*genai.Part{
					{Text: SystemPrompt},
				},
			},
			ResponseMIMEType: "application/json",
		}

		resp, err := client.Models.GenerateContent(ctx, model, genai.Text(req.Message), genConfig)
		if err != nil {
			log.Printf("error generating content: %v", err)
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}

		if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
			http.Error(w, "No response from AI", http.StatusInternalServerError)
			return
		}

		text := resp.Candidates[0].Content.Parts[0].Text
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, text)
	})

	log.Printf("Server starting on port %s...", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("http.ListenAndServe: %v", err)
	}
}

func enableCORS(w *http.ResponseWriter) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
	(*w).Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	(*w).Header().Set("Access-Control-Allow-Headers", "Content-Type")
}
