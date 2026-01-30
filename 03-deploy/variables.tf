# ==============================================================================
# INPUT VARIABLES: NETWORK RESOURCES
# ==============================================================================
# Defines input variables used to reference existing network components.
#
# Externalizing network names allows this configuration to be reused
# across environments without hardcoding infrastructure identifiers.
# ==============================================================================
variable "vpc_name" {
  description = "Name of the existing VPC network"
  type        = string
  default     = "packer-vpc"
}

variable "subnet_name" {
  description = "Name of the existing subnetwork"
  type        = string
  default     = "packer-subnet"
}

# ==============================================================================
# INPUT VARIABLES: PACKER IMAGE IDENTIFIERS
# ==============================================================================
# Defines input variables used to reference Packer-built images.
#
# Image names are supplied externally to decouple infrastructure
# provisioning from the image build pipeline.
# ==============================================================================
variable "games_image_name" {
  description = "Name of the Packer-built games image"
  type        = string
}

# ==============================================================================
# DATA SOURCE: GAMES PACKER IMAGE
# ==============================================================================
# Resolves the games image object by name within the target project.
#
# This data source allows Terraform to retrieve the image metadata
# required for boot disk initialization.
# ==============================================================================
data "google_compute_image" "games_packer_image" {
  name    = var.games_image_name
  project = local.credentials.project_id
}

# ==============================================================================
# INPUT VARIABLES: DESKTOP IMAGE IDENTIFIER
# ==============================================================================
# Defines the name of the Packer-built Windows desktop image.
# ==============================================================================
variable "desktop_image_name" {
  description = "Name of the Packer-built desktop image"
  type        = string
}

# ==============================================================================
# DATA SOURCE: DESKTOP PACKER IMAGE
# ==============================================================================
# Resolves the desktop image object by name within the target project.
#
# This data source is required to obtain the image self_link or ID
# used during Compute Engine boot disk provisioning.
# ==============================================================================
data "google_compute_image" "desktop_packer_image" {
  name    = var.desktop_image_name
  project = local.credentials.project_id
}
