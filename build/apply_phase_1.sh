#!/bin/bash

# First phase - build GCP infrastructure

# Check if the file "./credentials.json" exists
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

echo "NOTE: Phase 1 Building GCP Infrastructure"

cd 01-infrastructure/

terraform init
terraform apply -auto-approve

cd ..
