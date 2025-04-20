# First phase - build GCP infrastructure

# Check if the file "./credentials.json" exists
if (-Not (Test-Path "./credentials.json")) {
    Write-Error "ERROR: The file './credentials.json' does not exist."
    exit 1
}

Write-Host "NOTE: Phase 1 Building GCP Infrastructure"

Set-Location "01-infrastructure"

terraform init
terraform apply -auto-approve

Set-Location ".."
