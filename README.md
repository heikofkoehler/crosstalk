# 🇪🇸 Crosstalk AI

An AI-powered Spanish language learning application built on the **Crosstalk** method. The app provides high-quality Comprehensible Input by having an AI partner speak Spanish while providing real-time visual aids (SVG drawings) based on the user's English input.

## 🏗 Architecture

This project follows a "Zero-Cost" serverless-first philosophy using the Google Cloud ecosystem:

- **Frontend:** Flutter Web PWA hosted on **Firebase Hosting**.
- **Backend:** **Firebase Genkit** (Node.js/TypeScript) with conversational memory.
- **Intelligence:** **Gemini 2.5 Flash Lite** via Google AI SDK.
- **Auth:** Google Sign-In via **Firebase Authentication**.
- **Visuals:** Real-time AI-generated SVG paths rendered on a Flutter `CustomPainter`.

## 🚀 Key Features

- **Adaptive Difficulty:** Switch between Superbeginner, Beginner, and Intermediate modes.
- **¿Qué? (Simplify) Button:** Immediate request for simpler Spanish and clearer visual cues.
- **Conversational Memory:** The AI remembers your previous turns for a natural dialogue.
- **Interactive Canvas:** AI "draws" what it describes to maximize comprehension without translation.

---

## 🛠 Local Development

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js (v20+)](https://nodejs.org/)
- [Firebase CLI](https://firebase.google.com/docs/cli)

### 2. Backend Setup (Genkit)
1. Install dependencies:
   ```bash
   cd functions
   npm install
   ```
2. Build and start the emulator:
   ```bash
   npm run build
   cd ..
   firebase emulators:start --only functions
   ```

### 3. Frontend Setup (Flutter)
1. Install dependencies and run:
   ```bash
   cd flutter_app
   flutter pub get
   flutter run -d chrome --web-port=8888
   ```

---

## 📦 Production Deployment

### 1. Backend & Frontend Deployment
Deploy everything in one go from the root directory:
```bash
./deploy.sh          # Deploys Backend (Functions)
./deploy_frontend.sh # Deploys Frontend (Hosting)
```

---

## 🔒 Security & Privacy
- **API Key Safety:** Sensitive keys are managed via environment variables and are never checked into source control.
- **No PII Storage:** User audio is processed in-memory via the browser's Web Speech API and is never stored on servers.

## 📄 Documentation
For detailed technical mandates and the architectural roadmap, see [GEMINI.md](./GEMINI.md).
