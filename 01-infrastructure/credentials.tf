# ==============================================================================
# RANDOM PASSWORD: PACKER SERVICE ACCOUNT CREDENTIAL
# ==============================================================================
# Generates a strong, random password for the Packer service account.
#
# Design notes:
#   - Password length is set to 24 characters to provide sufficient entropy
#     for automated service credentials.
#   - Special characters are intentionally excluded to avoid shell escaping,
#     JSON encoding, and provisioning tool compatibility issues.
# ==============================================================================
resource "random_password" "generated" {
  length  = 24
  special = false
}

# ==============================================================================
# GOOGLE SECRET MANAGER: PACKER CREDENTIAL STORAGE
# ==============================================================================
# Defines a Google Secret Manager secret to securely store the Packer
# service account credentials.
#
# The secret is configured with automatic replication, allowing Google
# to manage regional availability and durability.
# ==============================================================================
resource "google_secret_manager_secret" "packer_secret" {
  secret_id = "packer-credentials"

  replication {
    auto {}
  }
}

# ==============================================================================
# SECRET VERSION: PACKER CREDENTIAL PAYLOAD
# ==============================================================================
# Creates a new version of the Packer credentials secret.
#
# The secret payload is stored as a JSON document containing:
#   - A static username used by automation ("packer")
#   - A dynamically generated password sourced from random_password
#
# This structure allows downstream systems (e.g., Packer builds) to
# programmatically retrieve credentials in a predictable format.
# ==============================================================================
resource "google_secret_manager_secret_version" "packer_secret_version" {
  secret = google_secret_manager_secret.packer_secret.id

  secret_data = jsonencode({
    username = "packer"
    password = random_password.generated.result
  })
}
