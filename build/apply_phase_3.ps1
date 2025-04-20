# Third phase - build Managed Instance Group

# Check if the file "./credentials.json" exists
if (-Not (Test-Path "./credentials.json")) {
    Write-Error "ERROR: The file './credentials.json' does not exist."
    exit 1
}

Write-Host "NOTE: Phase 3 Building Managed Instance Group"

# Extract the project_id using jq
$project_id = (Get-Content "./credentials.json" | ConvertFrom-Json).project_id

gcloud auth activate-service-account --key-file="./credentials.json" > $null 2> $null
$env:GOOGLE_APPLICATION_CREDENTIALS = "../credentials.json"

gcloud config set project $project_id

$LATEST_IMAGE = gcloud compute images list `
    --filter="name~'^flask-packer-image' AND family=flask-images" `
    --sort-by="~creationTimestamp" `
    --limit=1 `
    --format="value(name)"

# Check if LATEST_IMAGE is empty
if (-Not $LATEST_IMAGE) {
    Write-Error "ERROR: No latest image found for 'flask-packer-image' in family 'flask-images'."
    exit 1
}

$CURRENT_IMAGE = gcloud compute instance-templates describe flask-template `
    --format="get(properties.disks[0].initializeParams.sourceImage)" 2> $null | ForEach-Object {
        ($_ -split '/')[ -1 ]
    }

Set-Location "03-mig"
terraform init

# Conditional block if CURRENT_IMAGE is not empty and not equal to LATEST_IMAGE
if ($CURRENT_IMAGE -and ($CURRENT_IMAGE -ne $LATEST_IMAGE)) {
    Write-Host "NOTE: Updating resources as CURRENT_IMAGE ($CURRENT_IMAGE) is different from LATEST_IMAGE ($LATEST_IMAGE)."
    terraform destroy -var="flask_image_name=$CURRENT_IMAGE" -auto-approve  
}

terraform apply -var="flask_image_name=$LATEST_IMAGE" -auto-approve

# Check the exit code of the first Terraform apply
# There is a terraform bug about http health check readiness that sometimes requires
# a second apply

if ($LASTEXITCODE -ne 0) {
    terraform apply -var="flask_image_name=$LATEST_IMAGE" -auto-approve
} 

Set-Location ".."
