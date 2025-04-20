#!/bin/bash

# Second phase - Build the packer image

# Check if the file "./credentials.json" exists
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

# Extract the project_id using jq
project_id=$(jq -r '.project_id' "./credentials.json")

gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="../credentials.json"

cd 02-packer
echo "NOTE: Phase 2 Building Image with Packer"

packer init .

packer build \
  -var="project_id=$project_id"  \
  flask_image.pkr.hcl

cd ..
