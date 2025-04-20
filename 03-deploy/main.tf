# Google Cloud Provider Configuration
# Configures the Google Cloud provider using project details and credentials from a JSON file.
provider "google" {
  project     = local.credentials.project_id             # Specifies the project ID from the decoded credentials file.
  credentials = file("../credentials.json")              # Path to the credentials JSON file for authentication.
}

# Local Variables
# Reads and decodes the credentials.json file to extract necessary details like project ID and service account email.
locals {
  credentials            = jsondecode(file("../credentials.json")) # Decodes the JSON file into a usable map structure.
  service_account_email  = local.credentials.client_email          # Extracts the service account email from the decoded JSON.
}


data "google_compute_network" "packer_vpc" {
  name = "packer-vpc"
}

data "google_compute_subnetwork" "packer_subnet" {
  name    = "packer-subnet"
  region  = "us-central1"  
}

