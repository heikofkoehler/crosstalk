#!/bin/bash

echo "🚀 Starting Frontend Deployment to Firebase Hosting..."

# Ensure we are in the correct directory
if [ -d "flutter_app" ]; then
    cd flutter_app
else
    echo "❌ Error: flutter_app directory not found. Are you in the project root?"
    exit 1
fi

echo "---"
echo "🏗 Building Flutter Web App (Release Mode)..."
flutter build web --release

echo "---"
echo "☁️ Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo "---"
echo "✅ Frontend deployment complete!"
