# PowerShell script to delete GCP infrastructure

# First phase - delete GCP infrastructure

# Check if the file "./credentials.json" exists
if (!(Test-Path "./credentials.json")) {
    Write-Error "The file './credentials.json' does not exist."
    exit 1
}

Write-Host "NOTE: Destroying GCP Infrastructure"

# Navigate to the 01-infrastructure directory

Set-Location "01-infrastructure/"

# Initialize and destroy Terraform configuration
terraform init
terraform destroy -auto-approve

# Return to the original directory
Set-Location ..
