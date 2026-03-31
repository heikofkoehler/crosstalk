#!/bin/bash

# Configuration
PROJECT_ID="crosstalk-project"

echo "🚀 Starting Backend Deployment for $PROJECT_ID (Firebase Genkit)..."

# Build and Deploy to Firebase Functions
echo "---"
echo "🏗 Building and Deploying Genkit Functions..."
cd functions
npm run build
firebase deploy --only functions --project $PROJECT_ID
cd ..

echo "---"
echo "✅ Backend deployment complete!"
