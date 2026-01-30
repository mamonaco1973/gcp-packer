# ==============================================================================
# GOOGLE CLOUD PROVIDER CONFIGURATION
# ==============================================================================
# Configures the Google Cloud provider used by Terraform to manage
# resources within the target GCP project.
#
# Authentication is performed using a local service account credentials
# file. The project identifier is derived dynamically from the decoded
# credentials to avoid hardcoding environment-specific values.
# ==============================================================================
provider "google" {
  project     = local.credentials.project_id
  credentials = file("../credentials.json")
}

# ==============================================================================
# LOCAL VARIABLES: SERVICE ACCOUNT CREDENTIAL PARSING
# ==============================================================================
# Decodes the Google Cloud service account credentials file and exposes
# commonly referenced fields as local variables.
#
# Centralizing credential parsing ensures consistent usage of the
# project ID and service account identity across the configuration.
# ==============================================================================
locals {
  credentials = jsondecode(file("../credentials.json"))

  service_account_email = local.credentials.client_email
}

# ==============================================================================
# DATA SOURCES: EXISTING NETWORK INFRASTRUCTURE
# ==============================================================================
# Resolves references to pre-existing network resources in the project.
#
# These data sources allow Terraform to attach new resources to an
# existing VPC and subnet without managing their lifecycle.
# ==============================================================================
data "google_compute_network" "packer_vpc" {
  name = var.vpc_name
}

data "google_compute_subnetwork" "packer_subnet" {
  name   = var.subnet_name
  region = "us-central1"
}
