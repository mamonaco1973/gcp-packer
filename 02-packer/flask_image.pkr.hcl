packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.1.6"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "source_image_family" {
  description = "Source image family to base the build on (e.g., ubuntu-2404-lts-amd64)"
  type        = string
  default     = "ubuntu-2404-lts-amd64"
}

source "googlecompute" "packer_build_image" {
  project_id            = var.project_id
  zone                  = var.zone
  source_image_family   = var.source_image_family # Specifies the base image family
  ssh_username          = "ubuntu"                # Specify the SSH username
  machine_type          = "e2-micro"              # Smallest machine type for cost-effectiveness

  image_name            = "flask-packer-image-${local.timestamp}" # Use local.timestamp directly
  image_family          = "flask-images"          # Image family to group related images
  disk_size             = 20                      # Disk size in GB
}

build {
  sources = ["source.googlecompute.packer_build_image"]

  # Provisioner to run shell commands during the build
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /flask",      # Create the /flask directory
      "sudo chmod 777 /flask"      # Set permissions to allow access
    ]
  }

  # Provisioner to copy local scripts to the instance
  provisioner "file" {
    source      = "./scripts/"    # Path to the local scripts directory
    destination = "/flask/"       # Destination directory on the instance
  }

  # Provisioner to run a shell script during the build
  provisioner "shell" {
    script = "./install.sh"       # Path to the install script
  }
}
