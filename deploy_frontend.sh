#!/bin/bash

echo "🚀 Starting Frontend Deployment to Firebase Hosting..."

# Ensure we are in the correct directory
if [ -d "flutter_app" ]; then
    cd flutter_app
    echo "---"
    echo "🏗 Building Flutter Web App (Release Mode)..."
    flutter build web --release
    cd ..
else
    echo "❌ Error: flutter_app directory not found. Are you in the project root?"
    exit 1
fi

echo "---"
echo "☁️ Deploying to Firebase Hosting..."
firebase deploy --only hosting --project crosstalk-project

echo "---"
echo "✅ Frontend deployment complete!"
