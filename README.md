# 🇪🇸 Crosstalk AI

An AI-powered Spanish language learning application built on the **Crosstalk** method. The app provides high-quality Comprehensible Input by having an AI partner speak Spanish while providing real-time visual aids (SVG drawings) based on the user's English input.

## 🏗 Architecture

This project follows a "Zero-Cost" serverless-first philosophy using the Google Cloud ecosystem:

- **Frontend:** Flutter Web PWA hosted on **Firebase Hosting**.
- **Backend:** Go orchestrator running on **Cloud Run**.
- **Intelligence:** **Gemini 2.0 Flash Lite** via Vertex AI.
- **Auth:** Google Sign-In via **Firebase Authentication**.
- **Visuals:** Real-time AI-generated SVG paths rendered on a Flutter `CustomPainter`.

## 🚀 Key Features

- **Adaptive Difficulty:** Switch between Superbeginner, Beginner, and Intermediate modes to adjust vocabulary frequency.
- **¿Qué? (Simplify) Button:** Immediate request for simpler Spanish and clearer visual cues if you're confused.
- **Interactive Canvas:** AI "draws" what it describes to maximize comprehension without translation.
- **PWA Ready:** Installable on mobile and desktop for a native-like experience.

---

## 🛠 Local Development

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Go](https://go.dev/doc/install)
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
- [Firebase CLI](https://firebase.google.com/docs/cli)

### 2. Backend Setup (Go)
1. Authenticate with Google Cloud:
   ```bash
   gcloud auth application-default login
   ```
2. Run the local setup script (defaults to port 8888):
   ```bash
   ./setup_local.sh
   ```

### 3. Frontend Setup (Flutter)
1. Initialize Firebase for the project (run once):
   ```bash
   cd flutter_app
   flutterfire configure --project=crosstalk-project
   ```
2. Install dependencies and run:
   ```bash
   flutter pub get
   flutter run -d chrome --web-port=8888
   ```
   *Note: Ensure `http://localhost:8888` is an authorized JavaScript origin in your Google Cloud Console Credentials.*

---

## 📦 Production Deployment

### 1. One-Time Infrastructure Setup
Configure APIs, IAM permissions, and Artifact Registry:
```bash
./setup_iam.sh
```

### 2. Backend Deployment
Deploy the Go orchestrator to Cloud Run:
```bash
./deploy.sh
```

### 3. Frontend Deployment
Build and deploy the Flutter PWA to Firebase Hosting:
```bash
cd flutter_app
flutter build web --release
firebase deploy --only hosting
```

---

## 🔒 Security & Privacy
- **Workload Identity:** The backend uses service account roles to access Vertex AI without needing hardcoded API keys.
- **No PII Storage:** User audio is processed in-memory via the browser's Web Speech API and is never stored on servers.

## 📄 Documentation
For detailed technical mandates and the architectural roadmap, see [GEMINI.md](./GEMINI.md).
