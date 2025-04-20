variable "games_image_name" {
  description = "Name of the Packer built games image"
  type        = string                                                       
}

data "google_compute_image" "games_packer_image" {
  name    = var.games_image_name                      # Name of the image
  project = local.credentials.project_id              # GCP project ID
}