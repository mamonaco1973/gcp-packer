# NOTE: Validating credentials.json and testing the gcloud command

# Check if the file "credentials.json" exists
if (-Not (Test-Path "./credentials.json")) {
    Write-Error "The file './credentials.json' does not exist."
    exit 1
}

# Activate the service account using the credentials.json file
gcloud auth activate-service-account --key-file="./credentials.json"

# Extract the project_id using PowerShell's ConvertFrom-Json cmdlet
$credentials = Get-Content "./credentials.json" | ConvertFrom-Json
$project_id = $credentials.project_id

# NOTE: Enabling APIs needed for the build
gcloud config set project $project_id
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

# Create Firestore database
gcloud firestore databases create --location=us-central1 --type=firestore-native > $null 2> $null
