package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/vertexai/genai"
)

const SystemPrompt = `
ROLE: Spanish Crosstalk Partner.
CONSTRAINTS: 
- Always respond in Spanish.
- User speaks English.
- Level: Beginner (Adapt vocab frequency).
- Output Format: Strict JSON { "text": "...", "svg_draw": "..." }
- Visuals: Use simple SVG paths (e.g., <path d="..."/>) in the "svg_draw" field to illustrate what you are saying.
`

type ChatRequest struct {
	Message string `json:"message"`
	Level   string `json:"level"`
}

type ChatResponse struct {
	Text    string `json:"text"`
	SvgDraw string `json:"svg_draw"`
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	location := "us-central1"

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
		client, err := genai.NewClient(ctx, projectID, location)
		if err != nil {
			log.Printf("error creating client: %v", err)
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}
		defer client.Close()

		model := client.GenerativeModel("gemini-1.5-flash-002")
		model.SystemInstruction = &genai.ChildContent{
			Role: "system",
			Parts: []genai.Part{
				genai.Text(SystemPrompt),
			},
		}
		model.ResponseMIMEType = "application/json"

		resp, err := model.GenerateContent(ctx, genai.Text(req.Message))
		if err != nil {
			log.Printf("error generating content: %v", err)
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}

		if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
			http.Error(w, "No response from AI", http.StatusInternalServerError)
			return
		}

		part := resp.Candidates[0].Content.Parts[0]
		textPart, ok := part.(genai.Text)
		if !ok {
			http.Error(w, "Unexpected response format", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, string(textPart))
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
