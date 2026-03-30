#!/bin/bash

# Configuration
# Default to 8888 if PORT is not set
export PORT="${PORT:-8888}"
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-crosstalk-project}"

echo "🚀 Starting Crosstalk AI Local Environment..."
echo "Project ID: $GOOGLE_CLOUD_PROJECT"
echo "Port: $PORT"

# 1. Backend Setup
echo "---"
echo "📦 Preparing Go Backend..."
cd backend
go mod tidy

echo "🏃 Starting Backend Server on http://localhost:$PORT..."
go run main.go
