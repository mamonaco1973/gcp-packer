############################################
#              PACKER SETUP
############################################

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

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "") # Generate compact timestamp (YYYYMMDDHHMMSS)
                                                       # Used for unique image names
}

############################################
#           PARAMETER VARIABLES
############################################

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
  description = "Windows image family (e.g., windows-2022)"
  type        = string
  default     = "windows-2022"
}

variable "password" {
  description = "Password for the Windows Administrator account"
  type        = string
}

############################################
#      MAIN SOURCE BLOCK - GCP WINDOWS IMAGE
############################################

source "googlecompute" "windows_image" {
  project_id            = var.project_id
  zone                  = var.zone
  machine_type          = "e2-standard-2"
  source_image_family   = var.source_image_family
  disk_size             = 64
  disk_type             = "pd-balanced"
  image_name            = "desktop-image-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  communicator          = "winrm"
  winrm_username        = "Administrator"  
  winrm_password        = var.password
  winrm_insecure        = true
  network               = "packer-vpc"
  subnetwork            = "packer-subnet"

  metadata = {
    windows-startup-script-ps1 = templatefile("./bootstrap_win.ps1", {
      password = var.password
    })
  }

  tags = ["allow-winrm"]
}

############################################
#             BUILD PROCESS
############################################

build {
  sources = ["source.googlecompute.windows_image"]

  provisioner "windows-update" {}

  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
    script = "./security.ps1"
    environment_vars = [
      "PACKER_PASSWORD=${var.password}"
    ]
  }

  provisioner "powershell" {
    inline = [
      "mkdir C:\\mcloud"
    ]
  }

  provisioner "file" {
    source      = "./boot.ps1"
    destination = "C:\\mcloud\\"
  }

  provisioner "powershell" {
    script = "./chrome.ps1"
  }

  provisioner "powershell" {
    script = "./firefox.ps1"
  }

  provisioner "powershell" {
    script = "./desktop.ps1"
  }

  # Final Step: Generalize Windows with Sysprep for image reuse on GCP
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep for GCP image finalization...'",
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /shutdown /quiet"
    ]
  }
}
