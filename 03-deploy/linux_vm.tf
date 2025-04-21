resource "google_compute_instance" "games_vm" {
  name         = "games-vm"                 # Name of the instance.
  machine_type = "e2-micro"                 # Machine type for cost-efficient workloads.
  zone         = "us-central1-a"            # Deployment zone for the instance.
  allow_stopping_for_update = true
  
  # Boot Disk Configuration
  boot_disk {
    initialize_params {
      image = data.google_compute_image.games_packer_image.self_link 
    }
  }

  # Network Interface Configuration
  network_interface {
    network    = data.google_compute_network.packer_vpc.id           
    subnetwork = data.google_compute_subnetwork.packer_subnet.id     
    access_config {}                        # Automatically assigns a public IP for external access.
  }

  # Metadata for Startup Script with variable injection
  metadata_startup_script = templatefile("./scripts/startup_script.sh", {
    image = data.google_compute_image.games_packer_image.name
  })  # Renders the script with provided variables before instance boot.

  # Tags for Firewall Rules
  tags = ["allow-ssh", "allow-http"]        # Tags to match firewall rules for SSH and HTTP access.
  
}

# Output: Public IP of the Ubuntu VM
# Outputs the public IP address of the deployed VM.
output "games_public_ip" {
  value       = google_compute_instance.games_vm.network_interface[0].access_config[0].nat_ip  
                                                           # Retrieves the NAT IP of the instance.
  description = "The public IP address of the Game VM."    # Describes the output for clarity.
}
