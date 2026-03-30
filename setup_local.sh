#!/bin/bash

# Configuration
export GOOGLE_CLOUD_PROJECT="crosstalk"
export PORT="8080"

echo "🚀 Starting Crosstalk AI Local Environment..."
echo "Project ID: $GOOGLE_CLOUD_PROJECT"

# 1. Backend Setup
echo "---"
echo "📦 Preparing Go Backend..."
cd backend
go mod tidy

echo "🏃 Starting Backend Server on http://localhost:8080..."
go run main.go
