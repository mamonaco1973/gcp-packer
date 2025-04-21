#!/bin/bash

#-------------------------------------------------------------------------------
# STEP 0: Run environment validation script
#-------------------------------------------------------------------------------
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1  # Hard exit if environment validation fails
fi

#-------------------------------------------------------------------------------
# STEP 1: Provision base infrastructure 
#-------------------------------------------------------------------------------
cd 01-infrastructure                # Navigate to Terraform infra folder
terraform init                      # Initialize Terraform plugins/backend
terraform apply -auto-approve       # Apply infrastructure configuration without prompt
cd ..                               # Return to root directory


# Extract the project_id using jq
project_id=$(jq -r '.project_id' "./credentials.json")

gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/credentials.json"

password=$(gcloud secrets versions access latest --secret="packer-credentials" | jq -r '.password')

cd 02-packer
cd linux

packer init .

packer build \
  -var="project_id=$project_id"  \
  -var="password=$password" \
  linux_image.pkr.hcl

cd ..

cd windows
# packer init .

packer build \
  -var="project_id=$project_id"  \
  -var="password=$password" \
  windows_image.pkr.hcl

cd ..

cd ..

games_image=$(gcloud compute images list \
  --filter="name~'^games-image' AND family=games-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

if [[ -z "$games_image" ]]; then
  echo "ERROR: No latest image found for 'games-image' in family 'games-images'."
  exit 1
fi

echo "NOTE: Games image is $games_image"


desktop_image=$(gcloud compute images list \
  --filter="name~'^desktop-image' AND family=desktop-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

if [[ -z "$desktop_image" ]]; then
  echo "ERROR: No latest image found for 'desktop-image' in family 'desktop-images'."
  exit 1
fi

echo "NOTE: Desktop image is $desktop_image"


cd 03-deploy
terraform init
terraform apply \
    -var="games_image_name=$games_image" \
    -var="desktop_image_name=$desktop_image" \
    -auto-approve
cd ..



