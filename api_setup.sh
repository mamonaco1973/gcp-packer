#!/bin/bash
# ==============================================================================
# File: validate_gcloud.sh
# ==============================================================================
# Purpose:
#   Validates the local GCP service account credentials file, authenticates
#   gcloud using that identity, sets the active project, and enables all
#   required Google Cloud APIs for the build environment.
#
# Assumptions:
#   - credentials.json exists in the current working directory
#   - jq and gcloud are installed and available on PATH
# ==============================================================================

echo "NOTE: Validating credentials.json and testing gcloud authentication"

# ------------------------------------------------------------------------------
# Validate credentials file exists
# ------------------------------------------------------------------------------
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Authenticate gcloud using the service account credentials
# ------------------------------------------------------------------------------
gcloud auth activate-service-account --key-file="./credentials.json"

# ------------------------------------------------------------------------------
# Extract project ID from credentials file
# ------------------------------------------------------------------------------
project_id=$(jq -r '.project_id' "./credentials.json")

# ------------------------------------------------------------------------------
# Set active project and enable required APIs
# ------------------------------------------------------------------------------
echo "NOTE: Enabling required Google Cloud APIs for build"

gcloud config set project "${project_id}"

gcloud services enable compute.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable apigateway.googleapis.com
gcloud services enable servicemanagement.googleapis.com
gcloud services enable servicecontrol.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable iam.googleapis.com

# ------------------------------------------------------------------------------
# Create Firestore database (ignore if it already exists)
# ------------------------------------------------------------------------------
gcloud firestore databases create \
  --location=us-central1 \
  --type=firestore-native \
  > /dev/null 2>&1
