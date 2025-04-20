# Custom VPC
# Creates a custom Virtual Private Cloud (VPC) network without automatically created subnetworks.
resource "google_compute_network" "flask_vpc" {
  name                    = "flask-vpc"               # Unique name for the VPC.
  auto_create_subnetworks = false                     # Prevent automatic creation of subnetworks.
}

# Custom Subnet
# Defines a subnet in the custom VPC with a specific IP CIDR range.
resource "google_compute_subnetwork" "flask_subnet" {
  name          = "flask-subnet"                     # Unique name for the subnet.
  ip_cidr_range = "10.0.0.0/24"                      # CIDR range for the subnet.
  region        = "us-central1"                      # Region where the subnet is created.
  network       = google_compute_network.flask_vpc.id # Reference to the custom VPC.
}

# Firewall Rule: Allow HTTP Traffic
# Allows inbound HTTP traffic (port 80) from any IP address.
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"                             # Unique name for the firewall rule.
  network = google_compute_network.flask_vpc.id     # Reference to the custom VPC.

  allow {
    protocol = "tcp"                                 # Protocol allowed (TCP).
    ports    = ["80"]                                # HTTP port.
  }

  source_ranges = ["0.0.0.0/0"]                      # Allows traffic from any IP address.
}

# Firewall Rule: Allow Flask Traffic
# Allows inbound traffic to Flask application (port 8000) only for instances with the "allow-flask" tag.
resource "google_compute_firewall" "allow_flask" {
  name    = "allow-flask"                            # Unique name for the firewall rule.
  network = google_compute_network.flask_vpc.id      # Reference to the custom VPC.

  allow {
    protocol = "tcp"                                 # Protocol allowed (TCP).
    ports    = ["8000"]                              # Flask application port.
  }

  source_ranges = ["0.0.0.0/0"]                      # Allows traffic from any IP address.
  target_tags   = ["allow-flask"]                    # Restricts to instances with this tag.
}

# Firewall Rule: Allow SSH Traffic
# Allows inbound SSH traffic (port 22) only for instances with the "allow-ssh" tag.
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"                              # Unique name for the firewall rule.
  network = google_compute_network.flask_vpc.id      # Reference to the custom VPC.

  allow {
    protocol = "tcp"                                 # Protocol allowed (TCP).
    ports    = ["22"]                                # SSH port.
  }

  source_ranges = ["0.0.0.0/0"]                      # Allows traffic from any IP address.
  target_tags   = ["allow-ssh"]                      # Restricts to instances with this tag.
}

# Firewall Rule: Allow Firestore Traffic
# Allows outbound traffic to Firestore services over HTTP and HTTPS.
resource "google_compute_firewall" "allow_firestore" {
  name       = "allow-firestore"                     # Unique name for the firewall rule.
  network    = google_compute_network.flask_vpc.id   # Reference to the custom VPC.
  direction  = "EGRESS"                              # Specifies outbound traffic.

  allow {
    protocol = "tcp"                                 # Protocol allowed (TCP).
    ports    = ["80", "443"]                         # HTTP and HTTPS ports.
  }

  destination_ranges = ["0.0.0.0/0"]                 # Allows traffic to any IP address.
}

# Cloud Router
# Creates a Cloud Router for managing network address translation (NAT) in the VPC.
resource "google_compute_router" "flask_router" {
  name    = "flask-router"                           # Unique name for the router.
  network = google_compute_network.flask_vpc.id      # Reference to the custom VPC.
  region  = "us-central1"                            # Region where the router is created.
}

# NAT Configuration
# Configures Network Address Translation (NAT) for instances in the VPC to access the internet.
resource "google_compute_router_nat" "flask_nat" {
  name                                = "flask-nat"                             # Unique name for the NAT configuration.
  router                              = google_compute_router.flask_router.name # Reference to the Cloud Router.
  region                              = "us-central1"                           # Region where the NAT is configured.
  nat_ip_allocate_option              = "AUTO_ONLY"                             # Automatically allocate IPs for NAT.
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"         # Apply NAT to all subnets and IP ranges.
}

# Health Check
# Monitors the health of instances in the instance group
resource "google_compute_health_check" "http_health_check" {
  name                = "http-health-check"                             # Name of the health check
  check_interval_sec  = 5                                               # Frequency (in seconds) of health checks
  timeout_sec         = 5                                               # Timeout (in seconds) for each health check
  healthy_threshold   = 2                                               # Number of successful checks to mark the instance as healthy
  unhealthy_threshold = 2                                               # Number of failed checks to mark the instance as unhealthy

  # HTTP-specific health check configuration
  http_health_check {
    request_path = "/gtg"                                               # Path to send health check requests
    port         = 8000                                                 # Port for the HTTP service
  }
}
