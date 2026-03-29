# 🇪🇸 Proyecto Crosstalk: Technical Manifest

This document outlines the architecture for a "Zero-Cost" Comprehensible Input app. It leverages the Google Cloud ecosystem to provide an adaptive Spanish learning environment using the **Crosstalk** method.

---

## 🏗 System Architecture

The application is built on a **Serverless-First** philosophy to ensure the 2026 Free Tier quotas are maximized.

### 1. Frontend: Flutter Web (PWA)
* **Renderer:** Skia/CanvasKit for high-performance visual aids.
* **State Management:** `flutter_bloc` or `Signals` for reactive UI updates during streaming AI responses.
* **STT:** Browser-native `Web Speech API` (On-device, $0 cost).
* **TTS:** `google_generative_ai` integrated with Cloud Text-to-Speech (Neural2).

### 2. Backend: Cloud Run (The Orchestrator)
* **Runtime:** Go (for low cold-start latency)
* **Duty:** Acts as a secure proxy between the Flutter frontend and Vertex AI.
* **Security:** Uses **Workload Identity Federation** to access Vertex AI without storing sensitive service account keys in the frontend.

### 3. Intelligence: Vertex AI (Gemini 1.5 Flash)
* **Model:** `gemini-1.5-flash-002` (Optimized for low-latency dialogue).
* **Context Caching:** Implemented for the "System Instructions" to reduce input token costs for long-running sessions.

---

## 🛠 Project Configuration

### Firebase & GCP Setup
```bash
# Initialize Firebase
firebase init hosting
firebase init auth # Enable Google Provider

# Configure Cloud Run Service
gcloud run deploy crosstalk-backend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### Vertex AI System Instructions
The core logic resides in the **System Instructions** passed to the `GenerativeModel`.

```dart
final model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: _yourApiKey,
  systemInstruction: Content.system('''
    ROLE: Spanish Crosstalk Partner.
    CONSTRAINTS: 
    - Always respond in Spanish.
    - User speaks English.
    - Level: ${user.currentLevel} (Adapt vocab frequency).
    - Output Format: Strict JSON { "text": "...", "svg_draw": "..." }
  '''),
);
```

---

## 💰 Cost Analysis (Monthly Estimates)

| Service | Tier | Usage | Expected Cost |
| :--- | :--- | :--- | :--- |
| **Cloud Run** | Tier 1 | 2M Requests | **$0.00** (Free Tier) |
| **Vertex AI** | Flash | 1K Req/Day | **$0.00** (Free Tier) |
| **Firebase Auth**| Spark | 50K MAU | **$0.00** |
| **Cloud TTS** | Neural2 | 1M Chars | **$0.00** |
| **Total** | | | **$0.00** |

---

## 🚦 Implementation Roadmap

### Phase 1: The "Minimal Viable Handshake"
- [ ] Flutter Web PWA boilerplate with Google Sign-In.
- [ ] Integration with `window.speechSynthesis` for initial testing.
- [ ] Basic `POST` to Cloud Run returning a hardcoded Spanish response.

### Phase 2: The "Adaptive Brain"
- [ ] Implement the "Frequency Bucket" logic in the System Prompt.
- [ ] Add the "Que?" button to trigger automatic simplification loops.
- [ ] Context Caching for 10k+ token sessions.

### Phase 3: The "Visual Component"
- [ ] Use Gemini's JSON output to render simple SVG shapes on a Flutter `CustomPainter`.
- [ ] Implement "Drawing Mode" where the AI describes a scene as it "draws" it for the user.

---

## 🔒 Security Posture
* **App Check:** Enforced to prevent unauthorized API calls to the Cloud Run backend.
* **CORS:** Restricted to `*.web.app` and `localhost` during development.
* **PII:** No user audio is stored; all STT is processed in-memory and discarded.