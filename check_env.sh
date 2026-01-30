#!/bin/bash
# ==============================================================================
# File: check_env.sh
# ==============================================================================
# Purpose:
#   Validates that all required command-line tools are available and that
#   Google Cloud authentication can be performed using a local service
#   account credentials file.
#
# Behavior:
#   - Verifies required binaries exist in the current PATH
#   - Fails fast if any required command is missing
#   - Validates presence of credentials.json
#   - Attempts gcloud authentication using the service account key
# ==============================================================================

echo "NOTE: Validating that required commands are available in PATH."

# ------------------------------------------------------------------------------
# Required command-line tools
# ------------------------------------------------------------------------------
commands=("gcloud" "packer" "terraform" "jq")

# Track overall validation status
all_found=true

# ------------------------------------------------------------------------------
# Verify each required command is available
# ------------------------------------------------------------------------------
for cmd in "${commands[@]}"; do
  if ! command -v "${cmd}" > /dev/null 2>&1; then
    echo "ERROR: ${cmd} is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: ${cmd} is found in the current PATH."
  fi
done

# ------------------------------------------------------------------------------
# Fail if any required command is missing
# ------------------------------------------------------------------------------
if [ "${all_found}" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more required commands are missing."
  exit 1
fi

# ------------------------------------------------------------------------------
# Validate credentials file exists
# ------------------------------------------------------------------------------
echo "NOTE: Validating credentials.json and testing gcloud authentication."

if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Authenticate gcloud using the service account credentials
# ------------------------------------------------------------------------------
gcloud auth activate-service-account --key-file="./credentials.json"
