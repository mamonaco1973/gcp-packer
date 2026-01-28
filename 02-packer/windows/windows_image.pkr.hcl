# ==============================================================================
# PACKER SETUP: REQUIRED PLUGINS
# ==============================================================================
# Defines the required Packer plugins and versions used by this build.
#
# Pinning versions improves repeatability and reduces the risk of
# unexpected changes from upstream plugin updates.
# ==============================================================================
packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.0"
    }

    windows-update = {
      source  = "github.com/rgl/windows-update"
      version = "0.15.0"
    }
  }
}

# ==============================================================================
# LOCAL VARIABLES: TIMESTAMP UTILITY
# ==============================================================================
# Generates a compact timestamp suitable for resource naming.
#
# The resulting value is commonly used to create unique image names
# and reduce collisions across repeated builds.
# ==============================================================================
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# ==============================================================================
# INPUT VARIABLES: BUILD PARAMETERS
# ==============================================================================
# Defines externalized configuration values used by the build.
# ==============================================================================
variable "project_id" {
  description = "GCP project identifier used for image builds"
  type        = string
}

variable "zone" {
  description = "GCP zone in which the temporary build instance is created"
  type        = string
  default     = "us-central1-a"
}

variable "source_image_family" {
  description = "Base Windows image family used as the build starting point"
  type        = string
  default     = "windows-2022"
}

variable "password" {
  description = "Password assigned to the Packer-created Windows account"
  type        = string
}

variable "vpc" {
  description = "VPC network name used by the temporary build instance"
  type        = string
  default     = "packer-vpc"
}

variable "subnet" {
  description = "Subnetwork name used by the temporary build instance"
  type        = string
  default     = "packer-subnet"
}

# ==============================================================================
# SOURCE IMAGE DEFINITION: WINDOWS DESKTOP IMAGE ON GCE
# ==============================================================================
# Defines the Google Compute Engine source builder for a Windows image.
#
# This build uses WinRM as the communicator. A startup script configures
# WinRM, creates a dedicated provisioning user, and grants local admin
# rights so Packer can run provisioning steps.
# ==============================================================================
source "googlecompute" "windows_image" {
  project_id          = var.project_id
  zone                = var.zone
  machine_type        = "e2-standard-4"
  source_image_family = var.source_image_family

  disk_size = 128
  disk_type = "pd-balanced"

  image_name   = "desktop-image-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  image_family = "desktop-images"

  communicator   = "winrm"
  winrm_username = "packer_user"
  winrm_password = var.password

  winrm_insecure = true
  winrm_use_ntlm = true
  winrm_use_ssl  = true

  network    = var.vpc
  subnetwork = var.subnet

  # --------------------------------------------------------------------------
  # Instance metadata: bootstrap WinRM and provisioning user
  # --------------------------------------------------------------------------
  metadata = {
    windows-startup-script-cmd = <<EOT
        winrm quickconfig -quiet ^
        && net user packer_user "${var.password}" /add /Y ^
        && net localgroup administrators packer_user /add ^
        && winrm set winrm/config/service/auth @{Basic="true"}
    EOT
  }

  # --------------------------------------------------------------------------
  # Network tags: allow WinRM and RDP access via firewall rules
  # --------------------------------------------------------------------------
  tags = ["allow-winrm", "allow-rdp"]
}

# ==============================================================================
# BUILD CONFIGURATION: WINDOWS PROVISIONING WORKFLOW
# ==============================================================================
# Orchestrates provisioning steps executed against the temporary Windows
# build instance prior to image capture.
# ==============================================================================
build {
  sources = ["source.googlecompute.windows_image"]

  # --------------------------------------------------------------------------
  # Apply Windows Updates, then restart to finalize patch installation
  # --------------------------------------------------------------------------
  provisioner "windows-update" {}

  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  # --------------------------------------------------------------------------
  # Apply baseline security configuration
  # --------------------------------------------------------------------------
  provisioner "powershell" {
    script = "./security.ps1"

    environment_vars = [
      "PACKER_PASSWORD=${var.password}"
    ]
  }

  # --------------------------------------------------------------------------
  # Create working directory for local assets and scripts
  # --------------------------------------------------------------------------
  provisioner "powershell" {
    inline = [
      "mkdir C:\\mcloud"
    ]
  }

  # --------------------------------------------------------------------------
  # Transfer bootstrapping script(s) to the instance
  # --------------------------------------------------------------------------
  provisioner "file" {
    source      = "./boot.ps1"
    destination = "C:\\mcloud\\"
  }

  # --------------------------------------------------------------------------
  # Install common browsers used for validation and end-user workflows
  # --------------------------------------------------------------------------
  provisioner "powershell" {
    script = "./chrome.ps1"
  }

  provisioner "powershell" {
    script = "./firefox.ps1"
  }

  # --------------------------------------------------------------------------
  # Apply desktop customization and user experience configuration
  # --------------------------------------------------------------------------
  provisioner "powershell" {
    script = "./desktop.ps1"
  }

  # --------------------------------------------------------------------------
  # Generalize the OS with Sysprep to produce a reusable image artifact
  # --------------------------------------------------------------------------
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep for GCP image finalization...'",
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /generalize /shutdown /quiet"
    ]
  }
}
