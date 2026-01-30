# ==============================================================================
# GOOGLE COMPUTE INSTANCE: DESKTOP VM
# ==============================================================================
# Provisions a Windows-based Google Compute Engine VM using a
# Packer-built desktop image.
#
# The instance is attached to an existing VPC and subnet and is assigned
# an ephemeral public IP address for remote access and updates.
# ==============================================================================
resource "google_compute_instance" "desktop_vm" {
  name         = "desktop-vm"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  # Allows the instance to be safely stopped and restarted during
  # update operations instead of forcing recreation.
  allow_stopping_for_update = true

  # --------------------------------------------------------------------------
  # Boot disk configuration
  # --------------------------------------------------------------------------
  # Initializes the boot disk from the Packer-built Windows image to
  # ensure a consistent, preconfigured desktop environment.
  boot_disk {
    initialize_params {
      image = data.google_compute_image.desktop_packer_image.self_link
    }
  }

  # --------------------------------------------------------------------------
  # Network interface configuration
  # --------------------------------------------------------------------------
  # Attaches the instance to the target VPC and subnet and assigns an
  # ephemeral NAT IP address for external connectivity.
  network_interface {
    network    = data.google_compute_network.packer_vpc.id
    subnetwork = data.google_compute_subnetwork.packer_subnet.id

    access_config {}
  }

  # --------------------------------------------------------------------------
  # Startup script execution (Windows)
  # --------------------------------------------------------------------------
  # Delivers a PowerShell startup script to the instance at boot time.
  # templatefile() is used to inject runtime values into the script.
  metadata = {
    windows-startup-script-ps1 = templatefile(
      "./scripts/startup_script.ps1",
      {
        image = data.google_compute_image.desktop_packer_image.name
      }
    )
  }

  # --------------------------------------------------------------------------
  # Firewall tags
  # --------------------------------------------------------------------------
  # Applies network tags used by firewall rules to permit inbound RDP
  # traffic to the instance.
  tags = ["allow-rdp"]
}

# ==============================================================================
# OUTPUT: DESKTOP VM PUBLIC IP ADDRESS
# ==============================================================================
# Exposes the VM's ephemeral public NAT IP address for RDP access and
# automation workflows.
# ==============================================================================
output "desktop_public_ip" {
  value       = google_compute_instance.desktop_vm.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the Desktop VM"
}
