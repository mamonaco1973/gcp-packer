#!/bin/bash

# This script deletes all images in the current Google Cloud project with the family "flask-images".

# Set the image family to filter
IMAGE_FAMILY="flask-images"

# Retrieve all images with the specified family
IMAGES=$(gcloud compute images list --filter="family=${IMAGE_FAMILY}" --format="value(name)")

# Check if any images were found
if [ -z "$IMAGES" ]; then
  echo "WARNING: No images found with the family '${IMAGE_FAMILY}'."
  exit 0
fi

# Loop through the images and delete each one
echo "NOTE: Deleting images with the family '${IMAGE_FAMILY}'..."
for IMAGE in $IMAGES; do
  echo "NOTE: Deleting image: $IMAGE"
  gcloud compute images delete "$IMAGE" --quiet
done

echo "NOTE: All images with the family '${IMAGE_FAMILY}' have been deleted."

