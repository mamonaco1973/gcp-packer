#!/bin/bash

# ==============================================================================
# VALIDATE: DISPLAY DEPLOYED GCP VM ENDPOINTS
# ==============================================================================
# Print Terraform outputs for deployed GCP virtual machines.
# Run after a successful `terraform apply`.
# ==============================================================================

set -euo pipefail
cd 03-deploy

# ------------------------------------------------------------------------------
# VERIFY TERRAFORM INITIALIZATION
# ------------------------------------------------------------------------------
if [ ! -d ".terraform" ]; then
  echo "ERROR: Terraform is not initialized in this directory."
  echo "Run 'terraform init' before executing this script."
  exit 1
fi

# ------------------------------------------------------------------------------
# RETRIEVE TERRAFORM OUTPUTS
# ------------------------------------------------------------------------------
# GCP instances expose public IPs rather than DNS FQDNs.
#
DESKTOP_PUBLIC_IP=$(terraform output -raw desktop_public_ip)
GAMES_PUBLIC_IP=$(terraform output -raw games_public_ip)

# ------------------------------------------------------------------------------
# DISPLAY RESULTS
# ------------------------------------------------------------------------------
echo "============================================================"
echo " Google Cloud Virtual Machine Endpoints"
echo "============================================================"
echo
echo " Desktop VM Public IP:"
echo "   ${DESKTOP_PUBLIC_IP}"
echo
echo " Games VM Public IP:"
echo "   ${GAMES_PUBLIC_IP}"
echo "   http://${GAMES_PUBLIC_IP}"
echo
echo "============================================================"

cd ..
