#!/bin/bash
# ==============================================================================
# File: destroy.sh
# ==============================================================================
# Purpose:
#   Orchestrates a full cleanup workflow:
#     - Resolves the latest Packer image names (games + desktop) by family
#     - Destroys deployed VM infrastructure using Terraform
#     - Deletes custom images matching known prefixes (games|desktop)
#     - Destroys base infrastructure (VPC, subnet, firewall rules, etc.)
#
# Notes:
#   - This script assumes gcloud is authenticated and has access to the
#     target project.
#   - Image deletion is best-effort; failures are logged and cleanup
#     continues.
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 1: Resolve the latest games image from the games-images family
# ------------------------------------------------------------------------------
games_image=$(
  gcloud compute images list \
    --filter="name~'^games-image' AND family=games-images" \
    --sort-by="~creationTimestamp" \
    --limit=1 \
    --format="value(name)"
)

if [[ -z "${games_image}" ]]; then
  echo "ERROR: No latest image found for family 'games-images'."
  exit 1
fi

echo "NOTE: Games image is ${games_image}"

# ------------------------------------------------------------------------------
# Step 2: Resolve the latest desktop image from the desktop-images family
# ------------------------------------------------------------------------------
desktop_image=$(
  gcloud compute images list \
    --filter="name~'^desktop-image' AND family=desktop-images" \
    --sort-by="~creationTimestamp" \
    --limit=1 \
    --format="value(name)"
)

if [[ -z "${desktop_image}" ]]; then
  echo "ERROR: No latest image found for family 'desktop-images'."
  exit 1
fi

echo "NOTE: Desktop image is ${desktop_image}"

# ------------------------------------------------------------------------------
# Step 3: Destroy deployed infrastructure (VMs, IPs, etc.)
# ------------------------------------------------------------------------------
cd 03-deploy || exit 1
terraform init

terraform destroy \
  -var="games_image_name=${games_image}" \
  -var="desktop_image_name=${desktop_image}" \
  -auto-approve

cd .. || exit 1

# ------------------------------------------------------------------------------
# Step 4: Delete Packer-built images matching known prefixes
# ------------------------------------------------------------------------------
echo "NOTE: Fetching images starting with 'games' or 'desktop'..."

image_list=$(
  gcloud compute images list \
    --format="value(name)" \
    --filter="name~'^(games|desktop)'"
)

if [[ -z "${image_list}" ]]; then
  echo "NOTE: No images found starting with 'games' or 'desktop'."
else
  echo "NOTE: Deleting images..."
  for image in ${image_list}; do
    echo "NOTE: Deleting image: ${image}"
    gcloud compute images delete "${image}" --quiet \
      || echo "WARNING: Failed to delete image: ${image}"
  done
fi

# ------------------------------------------------------------------------------
# Step 5: Destroy base infrastructure (VPC, firewall rules, etc.)
# ------------------------------------------------------------------------------
cd 01-infrastructure || exit 1
terraform init
terraform destroy -auto-approve
cd .. || exit 1
