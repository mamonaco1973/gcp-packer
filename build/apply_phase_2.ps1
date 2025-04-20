# Second phase - Build the Packer image

# Check if the file "./credentials.json" exists
if (-Not (Test-Path "./credentials.json")) {
    Write-Error "ERROR: The file './credentials.json' does not exist."
    exit 1
}

# Extract the project_id using ConvertFrom-Json
$jsonContent = Get-Content "./credentials.json" -Raw | ConvertFrom-Json
$project_id = $jsonContent.project_id

# Activate the service account using gcloud
& gcloud auth activate-service-account --key-file="./credentials.json" > $null 2> $null

# Set the GOOGLE_APPLICATION_CREDENTIALS environment variable
$env:GOOGLE_APPLICATION_CREDENTIALS = "../credentials.json"

# Navigate to the Packer directory
Set-Location "02-packer"

# Initialize and build the Packer image
Write-Host "NOTE: Phase 2 Building Image with Packer"
& packer init .
& packer build -var "project_id=$project_id" flask_image.pkr.hcl

# Return to the previous directory
Set-Location ..
