# ==============================================================================
# GOOGLE CLOUD PROVIDER CONFIGURATION
# ==============================================================================
# Configures the Google Cloud provider used by all Terraform resources.
#
# This block defines:
#   - Which GCP project Terraform operates against
#   - Which identity Terraform uses for authentication and authorization
#
# Authentication is performed using a local service account credentials
# file generated from Google Cloud IAM.
# ==============================================================================
provider "google" {
  project     = local.credentials.project_id
  credentials = file("../credentials.json")
}

# ==============================================================================
# LOCAL VARIABLES: SERVICE ACCOUNT CREDENTIAL EXTRACTION
# ==============================================================================
# Decodes the Google Cloud service account credentials file and exposes
# commonly used fields as local variables.
#
# Centralizing credential parsing avoids hardcoding values such as the
# project ID or service account email throughout the configuration.
#
# Assumptions:
#   - The credentials file exists at the specified relative path
#   - The JSON structure matches the standard IAM service account format
# ==============================================================================
locals {
  credentials = jsondecode(file("../credentials.json"))

  service_account_email = local.credentials.client_email
}
