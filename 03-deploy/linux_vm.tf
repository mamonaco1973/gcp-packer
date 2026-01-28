# ==============================================================================
# GOOGLE COMPUTE INSTANCE: GAMES VM
# ==============================================================================
# Creates a low-cost Google Compute Engine VM instance based on a custom
# Packer-built image.
#
# The instance is attached to an existing VPC and subnet and is assigned
# an ephemeral public IP address for inbound access and validation.
# ==============================================================================
resource "google_compute_instance" "games_vm" {
  name         = "games-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  # Allows GCE to stop and restart the instance during update operations
  # instead of forcing a delete/recreate cycle.
  allow_stopping_for_update = true

  # --------------------------------------------------------------------------
  # Boot disk configuration
  # --------------------------------------------------------------------------
  # Initializes the boot disk from the selected Packer image to ensure the
  # VM starts with the pre-baked application and configuration state.
  boot_disk {
    initialize_params {
      image = data.google_compute_image.games_packer_image.self_link
    }
  }

  # --------------------------------------------------------------------------
  # Network interface configuration
  # --------------------------------------------------------------------------
  # Attaches the instance to the target VPC/subnet and assigns an ephemeral
  # NAT IP address to enable internet connectivity and external access.
  network_interface {
    network    = data.google_compute_network.packer_vpc.id
    subnetwork = data.google_compute_subnetwork.packer_subnet.id

    access_config {}
  }

  # --------------------------------------------------------------------------
  # Startup script configuration
  # --------------------------------------------------------------------------
  # Executes a startup script at boot time. templatefile() is used to inject
  # runtime values into the script without hardcoding them.
  metadata_startup_script = templatefile("./scripts/startup_script.sh", {
    image = data.google_compute_image.games_packer_image.name
  })

  # --------------------------------------------------------------------------
  # Firewall tags
  # --------------------------------------------------------------------------
  # Applies network tags used by firewall rules to permit inbound traffic.
  # Tags must match the target_tags values defined by firewall resources.
  tags = ["allow-ssh", "allow-http"]
}

# ==============================================================================
# OUTPUT: GAMES VM PUBLIC IP ADDRESS
# ==============================================================================
# Exposes the VM's ephemeral public NAT IP address for connectivity testing
# and automation workflows.
# ==============================================================================
output "games_public_ip" {
  value       = google_compute_instance.games_vm.network_interface[0].access_config[0].nat_ip
  description = "Public IP address of the Games VM"
}
