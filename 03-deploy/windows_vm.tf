resource "google_compute_instance" "desktop_vm" {
  name         = "desktop_vm"               # Name of the instance.
  machine_type = "e2-standard-2"            # Machine type for cost-efficient workloads.
  zone         = "us-central1-a"            # Deployment zone for the instance.
  allow_stopping_for_update = true
  
  # Boot Disk Configuration
  boot_disk {
    initialize_params {
      image = data.google_compute_image.desktop_packer_image.self_link
    }
  }

  # Network Interface Configuration
  network_interface {
    network    = data.google_compute_network.packer_vpc.id           
    subnetwork = data.google_compute_subnetwork.packer_subnet.id     
    access_config {}                        # Automatically assigns a public IP for external access.
  }

  metadata = {
    windows-startup-script-ps1 = templatefile("./scripts/startup_script.ps1", {
      image = data.google_compute_image.desktop_packer_image.name
    })
  }

  # Tags for Firewall Rules
  tags = ["allow-rdp"]                      # Tags to match firewall rules for SSH and HTTP access.

#   # Service Account Configuration
#   service_account {
#     email  = "default"                      # Uses the default service account for the project.
#     scopes = ["cloud-platform"]             # Grants access to all Google Cloud APIs.
#   }
}

# Output: Public IP of the Ubuntu VM
# Outputs the public IP address of the deployed VM.
output "desktop_public_ip" {
  value       = google_compute_instance.desktop_vm.network_interface[0].access_config[0].nat_ip  
                                                           # Retrieves the NAT IP of the instance.
  description = "The public IP address of the Desktop VM."    # Describes the output for clarity.
}
