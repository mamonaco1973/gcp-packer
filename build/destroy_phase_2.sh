#!/bin/bash

# First phase - delete GCP infrastructure

# Check if the file "./credentials.json" exists
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

echo "NOTE: Destroying GCP Infrastucture"

cd 01-infrastructure/

terraform init
terraform destroy -auto-approve

cd ..
