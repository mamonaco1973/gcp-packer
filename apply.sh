#!/bin/bash
# ==============================================================================
# File: apply.sh
# ==============================================================================
# Purpose:
#   Orchestrates a full GCP deployment workflow:
#     - Provision core infrastructure with Terraform
#     - Authenticate to GCP using a service account key
#     - Read the Packer password from Terraform state
#     - Build Linux and Windows images with Packer
#     - Discover the latest images by family
#     - Deploy test VMs using Terraform with the latest image names
#
# Notes:
#   - This script assumes credentials.json is present in the repo root.
#   - check_env.sh is expected to validate required tools and inputs.
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 0: Validate environment prerequisites
# ------------------------------------------------------------------------------
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# ------------------------------------------------------------------------------
# Step 1: Provision core infrastructure using Terraform
# ------------------------------------------------------------------------------
cd 01-infrastructure || exit 1
terraform init
terraform apply -auto-approve
password=$(terraform output -raw packer_password)
cd .. || exit 1

if [[ -z "${password}" ]]; then
  echo "ERROR: Failed to read the packer password from Terraform state."
  exit 1
fi

# ------------------------------------------------------------------------------
# Step 2: Extract project ID and authenticate to GCP
# ------------------------------------------------------------------------------
project_id=$(jq -r '.project_id' "./credentials.json")

gcloud auth activate-service-account \
  --key-file="./credentials.json" \
  > /dev/null 2>&1

export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/credentials.json"

# ------------------------------------------------------------------------------
# Step 3: Build images using Packer (Linux, then Windows)
# ------------------------------------------------------------------------------
cd 02-packer/linux || exit 1
packer init .

packer build \
  -var="project_id=${project_id}" \
  -var="password=${password}" \
  linux_image.pkr.hcl

cd ../windows || exit 1
packer build \
  -var="project_id=${project_id}" \
  -var="password=${password}" \
  windows_image.pkr.hcl

cd ../.. || exit 1

# ------------------------------------------------------------------------------
# Step 4: Resolve latest images from GCP by family
# ------------------------------------------------------------------------------
games_image=$(
  gcloud compute images list \
    --filter="name~'^games-image' AND family=games-images" \
    --sort-by="~creationTimestamp" \
    --limit=1 \
    --format="value(name)"
)

if [[ -z "${games_image}" ]]; then
  echo "ERROR: No latest image found for family 'games-images'."
  exit 1
fi

echo "NOTE: Games image is ${games_image}"

desktop_image=$(
  gcloud compute images list \
    --filter="name~'^desktop-image' AND family=desktop-images" \
    --sort-by="~creationTimestamp" \
    --limit=1 \
    --format="value(name)"
)

if [[ -z "${desktop_image}" ]]; then
  echo "ERROR: No latest image found for family 'desktop-images'."
  exit 1
fi

echo "NOTE: Desktop image is ${desktop_image}"

# ------------------------------------------------------------------------------
# Step 5: Deploy VM resources using Terraform and latest image names
# ------------------------------------------------------------------------------
cd 03-deploy || exit 1
terraform init

terraform apply \
  -var="games_image_name=${games_image}" \
  -var="desktop_image_name=${desktop_image}" \
  -auto-approve

cd ..

#-------------------------------------------------------------------------------
# STEP 6: Validate the build.
#-------------------------------------------------------------------------------

./validate.sh

