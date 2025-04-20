# PowerShell script to delete GCP infrastructure

# First phase - delete GCP infrastructure

# Check if the file "./credentials.json" exists
if (!(Test-Path "./credentials.json")) {
    Write-Error "The file './credentials.json' does not exist."
    exit 1
}

Write-Host "NOTE: Destroying MIG"

# Extract the project_id using ConvertFrom-Json
$jsonContent = Get-Content "./credentials.json" | ConvertFrom-Json
$project_id = $jsonContent.project_id

# Activate the service account and set GCP project
gcloud auth activate-service-account --key-file="./credentials.json" > $null 2> $null
$env:GOOGLE_APPLICATION_CREDENTIALS = "../credentials.json"

gcloud config set project $project_id

# Get the latest image in the flask-images family
$LATEST_IMAGE = gcloud compute images list `
    --filter="name~'^flask-packer-image' AND family=flask-images" `
    --sort-by="~creationTimestamp" `
    --limit=1 `
    --format="value(name)"

# Check if LATEST_IMAGE is empty
if ([string]::IsNullOrEmpty($LATEST_IMAGE)) {
    Write-Error "No latest image found for 'flask-packer-image' in family 'flask-images'."
    exit 1
}

# Navigate to the 02-infrastructure directory

Set-Location "03-mig/"

# Initialize and destroy Terraform configuration
terraform init
terraform destroy -var="flask_image_name=$LATEST_IMAGE" -auto-approve

# Return to the original directory
Set-Location ..
