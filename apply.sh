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


cd 02-packer
cd linux
packer init .

packer build \
  -var="project_id=$project_id"  \
  -var="password=furby" \
  linux_image.pkr.hcl

cd ..
cd ..
