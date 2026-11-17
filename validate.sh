#!/bin/bash
# ==============================================================================
# validate.sh — print what you need to try the lab
#
# Both VMs are public: the games VM answers on HTTP, the Windows desktop VM
# on RDP. GCP gives them public IPs rather than DNS names, so the addresses
# come from the 03-deploy Terraform outputs. Both images carry the packer
# account, whose password get_password.sh reads from the 01-infrastructure
# Terraform state.
# ==============================================================================

set -euo pipefail

cd "$(dirname "$0")"

games_ip=$(terraform -chdir=03-deploy output -raw games_public_ip 2>/dev/null || true)
desktop_ip=$(terraform -chdir=03-deploy output -raw desktop_public_ip 2>/dev/null || true)

echo ""
echo "============================================================================"
echo "Packer Images - Validation Output"
echo "============================================================================"
echo ""

if [ -n "${games_ip}" ]; then
  printf "NOTE: %-22s %s\n" "Games URL:" "http://${games_ip}"
else
  printf "WARN: %-22s %s\n" "Games VM:" "not found"
fi

if [ -n "${desktop_ip}" ]; then
  printf "NOTE: %-22s %s\n" "Windows VM (RDP):" "${desktop_ip}"
else
  printf "WARN: %-22s %s\n" "Windows VM (RDP):" "not found"
fi
echo ""

./get_password.sh
echo ""
