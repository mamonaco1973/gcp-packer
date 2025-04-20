# Static Global IP Address
# This resource defines a global static IP address for the load balancer,
# ensuring the IP address remains consistent even if the load balancer is updated or recreated.
resource "google_compute_global_address" "lb_ip" {
  name = "flask-lb-ip"
}

# Backend Service
# Configures the backend service to manage traffic distribution to the instance group.
# The health check ensures the backend instances are healthy before routing traffic.
resource "google_compute_backend_service" "backend_service" {
  name                  = "flask-backend-service"        # Unique name for the backend service.
  protocol              = "HTTP"                         # Protocol used for communication with backend instances.
  port_name             = "http"                         # Matches the named port in the instance group configuration.
  health_checks         = [data.google_compute_health_check.http_health_check.self_link] 
                                                         # Reference to the health check resource.
  timeout_sec           = 10                             # Timeout for backend instance response in seconds.
  load_balancing_scheme = "EXTERNAL"                     # Specifies this is an external load balancer.

  # Backend block defines the backend instance group and its load balancing properties.
  backend {
    group           = google_compute_region_instance_group_manager.instance_group_manager.instance_group # Reference to the instance group.
    balancing_mode  = "UTILIZATION"                        # Balances traffic based on resource utilization.
  }
}

# URL Map
# Maps incoming HTTP requests to the appropriate backend service.
resource "google_compute_url_map" "url_map" {
  name            = "flask-alb"                           # Unique name for the URL map.
  default_service = google_compute_backend_service.backend_service.self_link # Routes all traffic to the backend service by default.
}

# Target HTTP Proxy
# Configures an HTTP proxy that directs requests to the specified URL map.
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "flask-http-proxy"                            # Unique name for the HTTP proxy.
  url_map = google_compute_url_map.url_map.id             # Reference to the URL map resource.
}

# Forwarding Rule
# Defines the forwarding rule to handle incoming requests and direct them to the HTTP proxy.
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "flask-http-forwarding-rule"    # Unique name for the forwarding rule.
  ip_address            = google_compute_global_address.lb_ip.address 
                                                          # Uses the static IP address from the global address resource.
  target                = google_compute_target_http_proxy.http_proxy.self_link 
                                                          # Sends requests to the HTTP proxy.
  port_range            = "80"                            # Listens for incoming requests on port 80 (HTTP).
  load_balancing_scheme = "EXTERNAL"                      # Specifies this is an external load balancer.
}
