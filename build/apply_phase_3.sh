#!/bin/bash

# Third phase - Build Managed Instance Group

# Check if the file "./credentials.json" exists
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

echo "NOTE: Phase 3 Building Managed Instance Group"

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

CURRENT_IMAGE=$(gcloud compute instance-templates describe flask-template --format="get(properties.disks[0].initializeParams.sourceImage)" 2> /dev/null | awk -F'/' '{print $NF}')

# Conditional block if CURRENT_IMAGE is not empty and not equal to LATEST_IMAGE
if [[ -n "$CURRENT_IMAGE" && "$CURRENT_IMAGE" != "$LATEST_IMAGE" ]]; then
  echo "NOTE: Updating resources as CURRENT_IMAGE ($CURRENT_IMAGE) is different from LATEST_IMAGE ($LATEST_IMAGE)."
  terraform destroy -var="flask_image_name=$CURRENT_IMAGE" -auto-approve  
fi

terraform init
terraform apply -var="flask_image_name=$LATEST_IMAGE" -auto-approve

# Check the exit code of the first terraform apply
# There is a terraform bug about http health check readiness that sometimes requires
# a second apply

if [ $? -ne 0 ]; then
    terraform apply -var="flask_image_name=$LATEST_IMAGE" -auto-approve
fi

cd ..
