# ==============================================================================
# PACKER CONFIGURATION: REQUIRED PLUGINS
# ==============================================================================
# Defines the required Packer plugins and their versions.
#
# Pinning plugin versions ensures reproducible builds and prevents
# unexpected behavior from upstream plugin changes.
# ==============================================================================
packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.1.6"
    }
  }
}

# ==============================================================================
# LOCAL VARIABLES: TIMESTAMP UTILITY
# ==============================================================================
# Generates a compact timestamp suitable for use in resource names.
#
# The timestamp is stripped of separators to produce a sortable,
# collision-resistant suffix for image naming.
# ==============================================================================
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# ==============================================================================
# INPUT VARIABLES: BUILD PARAMETERS
# ==============================================================================
# Defines externalized configuration values used by the Packer build.
# ==============================================================================
variable "project_id" {
  description = "GCP project identifier used for image builds"
  type        = string
  default     = "debug-project-446221"
}

variable "zone" {
  description = "GCP zone in which the temporary build instance is created"
  type        = string
  default     = "us-central1-a"
}

variable "source_image_family" {
  description = "Base image family used as the build starting point"
  type        = string
  default     = "ubuntu-2404-lts-amd64"
}

variable "password" {
  description = "The password for the packer account"    # Will be passed into SSH provisioning script
}

# ==============================================================================
# SOURCE IMAGE DEFINITION: GOOGLE COMPUTE ENGINE
# ==============================================================================
# Defines the Google Compute Engine source image used by Packer.
#
# A temporary VM is launched from the specified source image family,
# provisioned, and then captured as a reusable custom image.
# ==============================================================================
source "googlecompute" "packer_build_image" {
  project_id          = var.project_id
  zone                = var.zone
  source_image_family = var.source_image_family
  ssh_username        = "ubuntu"
  machine_type        = "e2-micro"

  image_name   = "games-image-${local.timestamp}"
  image_family = "games-images"
  disk_size    = 20
}

# ==============================================================================
# BUILD CONFIGURATION: IMAGE PROVISIONING WORKFLOW
# ==============================================================================
# Orchestrates the provisioning steps executed against the temporary
# build instance before image capture.
# ==============================================================================
build {
  sources = ["source.googlecompute.packer_build_image"]

  # --------------------------------------------------------------------------
  # Prepare temporary directory for application assets
  # --------------------------------------------------------------------------
  provisioner "shell" {
    inline = ["mkdir -p /tmp/html"]
  }

  # --------------------------------------------------------------------------
  # Transfer static HTML content to the build instance
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "./html/"
    destination = "/tmp/html/"
  }

  # --------------------------------------------------------------------------
  # Install and configure required system packages
  # --------------------------------------------------------------------------
  provisioner "shell" {
    script = "./install.sh"
  }

  # --------------------------------------------------------------------------
  # Configure SSH access using a supplied password
  # --------------------------------------------------------------------------
  provisioner "shell" {
    script = "./config_ssh.sh"

    environment_vars = [
      "PACKER_PASSWORD=${var.password}"
    ]
  }
}
