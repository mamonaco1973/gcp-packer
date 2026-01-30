# ==============================================================================
# CUSTOM VPC: ISOLATED NETWORK FOR PACKER BUILDS
# ==============================================================================
# Defines a custom Google Cloud VPC used exclusively for Packer image
# build operations.
#
# Auto-created subnetworks are disabled to ensure full control over
# IP addressing, regional placement, and firewall boundaries.
# ==============================================================================
resource "google_compute_network" "packer_vpc" {
  name                    = "packer-vpc"
  auto_create_subnetworks = false
}

# ==============================================================================
# CUSTOM SUBNET: REGIONAL IP ADDRESS SPACE
# ==============================================================================
# Creates a regional subnet within the custom Packer VPC.
#
# The subnet provides a dedicated RFC1918 address range for build
# instances launched during image creation.
# ==============================================================================
resource "google_compute_subnetwork" "packer_subnet" {
  name          = "packer-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.packer_vpc.id
}

# ==============================================================================
# FIREWALL RULE: ALLOW INBOUND HTTP TRAFFIC
# ==============================================================================
# Allows inbound HTTP traffic on TCP port 80.
#
# This rule supports validation of Linux image builds that expose
# web services during or after the Packer provisioning phase.
# ==============================================================================
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.packer_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# ==============================================================================
# FIREWALL RULE: ALLOW INBOUND RDP TRAFFIC
# ==============================================================================
# Allows inbound Remote Desktop Protocol (RDP) access to Windows
# instances during image build and validation.
#
# Access is restricted to instances explicitly tagged for RDP.
# ==============================================================================
resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"
  network = google_compute_network.packer_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-rdp"]
}

# ==============================================================================
# FIREWALL RULE: ALLOW INBOUND SSH TRAFFIC
# ==============================================================================
# Allows inbound Secure Shell (SSH) access for Linux-based image
# provisioning and debugging.
#
# This rule applies only to instances explicitly tagged for SSH access.
# ==============================================================================
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.packer_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}

# ==============================================================================
# FIREWALL RULE: ALLOW INBOUND WINRM TRAFFIC
# ==============================================================================
# Allows inbound Windows Remote Management (WinRM) traffic over HTTPS.
#
# This rule is required for Packer to provision Windows images using
# secure WinRM connections.
# ==============================================================================
resource "google_compute_firewall" "allow_winrm" {
  name    = "allow-winrm"
  network = google_compute_network.packer_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["5986"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-winrm"]
}
