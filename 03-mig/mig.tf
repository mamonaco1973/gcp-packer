# Instance Template
# This resource defines the template used to create instances in the managed instance group.
resource "google_compute_instance_template" "flask_template" {
  name         = "flask-template"                                       # Name of the instance template
  machine_type = "e2-micro"                                             # Machine type specifies the type of virtual machine to use

  # Tags for the VM instances
  # These tags are used for network firewall rules (e.g., allowing HTTP and SSH traffic)
  tags = ["allow-flask", "allow-ssh"]

  # Disk configuration
  disk {
    auto_delete  = true                                                   # Disk will be deleted when the instance is deleted
    boot         = true                                                   # Marks this disk as the boot disk
    source_image = data.google_compute_image.flask_packer_image.self_link # Uses the Packer-built image
  }

  # Network configuration
  network_interface {
    network    = data.google_compute_network.flask_vpc.id                    # VPC network reference
    subnetwork = data.google_compute_subnetwork.flask_subnet.id              # Subnet within the VPC
  }

  # Service account configuration
  service_account {
    email  = local.service_account_email                                # Service account email address
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]         # Scopes for API access
  }
}

# Regional Managed Instance Group
# Defines a managed instance group to automatically manage multiple instances
resource "google_compute_region_instance_group_manager" "instance_group_manager" {
  name               = "flask-instance-group"                           # Name of the managed instance group
  base_instance_name = "flask-instance"                                 # Base name for the instances in the group
  target_size        = 2                                                # Desired number of instances in the group
  region             = "us-central1"                                    # Region where the group will be deployed
 
  # Instance template to use for creating instances
  version {
    instance_template = google_compute_instance_template.flask_template.self_link
  }

  # Named port for the instance group
  named_port {
    name = "http"                                                       # Name of the port
    port = 8000                                                         # Port number for the HTTP service
  }

  # Auto-healing policies
  auto_healing_policies {
    health_check      = data.google_compute_health_check.http_health_check.self_link 
                                                                        # Health check resource
    initial_delay_sec = 300                                             # Time (in seconds) to wait before checking instance health
  }
}

# Regional Autoscaler
# Automatically adjusts the number of instances in the managed instance group
resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "flask-autoscaler"                                           # Name of the autoscaler
  target = google_compute_region_instance_group_manager.instance_group_manager.self_link # Target managed instance group
  region = "us-central1"                                                # Region where the autoscaler operates

  # Autoscaling policy configuration
  autoscaling_policy {
    max_replicas      = 4                                               # Maximum number of instances
    min_replicas      = 2                                               # Minimum number of instances

    # Target CPU utilization for scaling
    cpu_utilization {
      target = 0.6                                                      # Scale based on 60% CPU usage
    }

    cooldown_period = 60                                                # Time (in seconds) to wait between scaling actions
  }
}

# Variable for Image Name
# Defines a variable to pass the name of the Packer-built image
variable "flask_image_name" {
  description = "Name of the Packer-built image to use in the instance template" # Description of the variable
  type        = string                                                           # Type of the variable
}

# Data Resource for Packer-Built Image
# Retrieves information about the Packer-built image from GCP
data "google_compute_image" "flask_packer_image" {
  name    = var.flask_image_name                                    # Name of the image
  project = local.credentials.project_id                            # GCP project ID
}
