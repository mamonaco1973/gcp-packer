#!/bin/bash

# First phase - delete GCP infrastructure

# Check if the file "./credentials.json" exists
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

echo "NOTE: Destroying MIG Instance"

# Extract the project_id using jq
project_id=$(jq -r '.project_id' "./credentials.json")

gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="../credentials.json"

gcloud config set project $project_id

LATEST_IMAGE=$(gcloud compute images list \
  --filter="name~'^flask-packer-image' AND family=flask-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

# Check if LATEST_IMAGE is empty
if [[ -z "$LATEST_IMAGE" ]]; then
  echo "ERROR: No latest image found for 'flask-packer-image' in family 'flask-images'."
  exit 1
fi

cd 03-mig

terraform init
terraform destroy -var="flask_image_name=$LATEST_IMAGE" -auto-approve

cd ..
