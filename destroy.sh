#!/bin/bash

games_image=$(gcloud compute images list \
  --filter="name~'^games-image' AND family=games-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

if [[ -z "$games_image" ]]; then
  echo "ERROR: No latest image found for 'games-image' in family 'games-images'."
  exit 1
fi

echo "NOTE: Games image is $games_image"

desktop_image=$(gcloud compute images list \
  --filter="name~'^desktop-image' AND family=desktop-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

if [[ -z "$desktop_image" ]]; then
  echo "ERROR: No latest image found for 'desktop-image' in family 'desktop-images'."
  exit 1
fi

echo "NOTE: Desktop image is $desktop_image"

cd 03-deploy
terraform init
terraform destroy \
     -var="games_image_name=$games_image" \
     -var="desktop_image_name=$desktop_image" \
     -auto-approve
cd ..


# List all images that start with "games" or "desktop"
echo "NOTE: Fetching images starting with 'games' or 'desktop'..."
image_list=$(gcloud compute images list --format="value(name)" --filter="name~'^(games|desktop)'")

# Log what we found
if [ -z "$image_list" ]; then
  echo "NOTE: No images found starting with 'games' or 'desktop'. Continuing..."
else
  # Loop through and delete each image
  echo "NOTE: Deleting images..."
  for image in $image_list; do
    echo "NOTE: Deleting image: $image"
    gcloud compute images delete "$image" --quiet || echo "WARNING: Failed to delete image: $image"
  done
fi


cd 01-infrastructure
terraform init
terraform destroy -auto-approve
cd ..

