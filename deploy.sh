#!/bin/bash

# Configuration
PROJECT_ID="crosstalk-project"
REGION="us-central1"
REPO_NAME="crosstalk-repo"
SERVICE_NAME="crosstalk-backend"

echo "🚀 Starting Full Deployment for $PROJECT_ID..."

# 1. Enable APIs
echo "---"
echo "🔑 Enabling GCP Services..."
gcloud services enable run.googleapis.com \
                       artifactregistry.googleapis.com \
                       aiplatform.googleapis.com \
                       cloudbuild.googleapis.com \
                       --project=$PROJECT_ID

# 1.5. Configure Build Service Account Permissions
# Recent GCP changes require explicit permissions for the default compute service account
# to perform builds and access storage buckets.
echo "---"
echo "🛡 Configuring Build Service Account permissions..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
COMPUTE_SVC_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

echo "Granting roles to $COMPUTE_SVC_ACCOUNT..."
CURRENT_POLICY=$(gcloud projects get-iam-policy $PROJECT_ID --format=json)

for ROLE in "roles/cloudbuild.builds.builder" "roles/storage.admin" "roles/artifactregistry.writer" "roles/logging.logWriter" "roles/aiplatform.user"; do
    if echo "$CURRENT_POLICY" | grep -q "\"role\": \"$ROLE\"" && echo "$CURRENT_POLICY" | grep -q "$COMPUTE_SVC_ACCOUNT"; then
        echo "Role $ROLE already granted to $COMPUTE_SVC_ACCOUNT."
    else
        echo "Granting $ROLE to $COMPUTE_SVC_ACCOUNT..."
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:$COMPUTE_SVC_ACCOUNT" \
            --role="$ROLE" \
            --project=$PROJECT_ID --quiet > /dev/null
    fi
done

# 2. Create Artifact Registry if it doesn't exist
echo "---"
echo "📦 Checking Artifact Registry..."
gcloud artifacts repositories describe $REPO_NAME --location=$REGION --project=$PROJECT_ID &>/dev/null
if [ $? -ne 0 ]; then
    echo "Creating repository $REPO_NAME..."
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="Crosstalk Go Backend" \
        --project=$PROJECT_ID
else
    echo "Repository $REPO_NAME already exists."
fi

# 3. Build and Deploy to Cloud Run
echo "---"
echo "🏗 Building and Deploying $SERVICE_NAME..."
# Build and push to Artifact Registry, then deploy from image
gcloud run deploy $SERVICE_NAME \
    --source ./backend \
    --region $REGION \
    --allow-unauthenticated \
    --set-env-vars="GOOGLE_CLOUD_PROJECT=$PROJECT_ID" \
    --project=$PROJECT_ID

echo "---"
echo "✅ Backend deployment complete!"
echo "Please find your Cloud Run Service URL above and update your Flutter main.dart."
