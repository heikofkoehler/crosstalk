#!/bin/bash

# Configuration
PROJECT_ID="crosstalk-project"
REGION="us-central1"
SERVICE_NAME="crosstalk-backend"

echo "🚀 Starting Deployment for $PROJECT_ID..."

# Build and Deploy to Cloud Run
echo "---"
echo "🏗 Building and Deploying $SERVICE_NAME..."
cd backend
gcloud run deploy $SERVICE_NAME \
    --source . \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars="GOOGLE_CLOUD_PROJECT=$PROJECT_ID,GEMINI_API_KEY=$GEMINI_API_KEY" \
    --project=$PROJECT_ID
cd ..

echo "---"
echo "✅ Backend deployment complete!"
echo "Service URL: $(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)' --project $PROJECT_ID)"
