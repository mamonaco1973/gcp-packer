############################################
# RANDOM PASSWORD: SECURE CREDENTIAL FOR PACKER
############################################
resource "random_password" "generated" {
  length  = 24                    # Password length (strong enough for automation)
  special = false                 # No special characters (avoids compatibility issues with some scripts)
}

# Create secret for Packer credentials in GCP Secret Manager
resource "google_secret_manager_secret" "packer_secret" {
  secret_id = "packer-credentials"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "packer_secret_version" {
  secret      = google_secret_manager_secret.packer_secret.id
  secret_data = jsonencode({
    username = "packer"
    password = random_password.generated.result
  })
}
