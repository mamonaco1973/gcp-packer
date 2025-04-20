# This script deletes all images in the current Google Cloud project with the family "flask-images".

# Set the image family to filter
$imageFamily = "flask-images"

# Retrieve all images with the specified family
$images = gcloud compute images list --filter="family=$imageFamily" --format="value(name)"

# Check if any images were found
if (-not $images) {
    Write-Host "WARNING: No images found with the family '$imageFamily'."
    exit 0
}

# Loop through the images and delete each one
Write-Host "NOTE: Deleting images with the family '$imageFamily'..."
foreach ($image in $images) {
    Write-Host "NOTE: Deleting image: $image"
    gcloud compute images delete $image --quiet
}

Write-Host "NOTE: All images with the family '$imageFamily' have been deleted."
