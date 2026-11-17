# ==============================================================================
# PACKER ACCOUNT PASSWORD
# ==============================================================================
# A strong random password for the local packer account that both Packer
# builds create. Terraform keeps it in this phase's state; apply.sh reads it
# from the output below, and get_password.sh prints it.
#
# Design notes:
#   - Password length is set to 24 characters to provide sufficient entropy
#     for automated service credentials.
#   - Special characters are intentionally excluded to avoid shell escaping,
#     JSON encoding, and provisioning tool compatibility issues.
#   - Anyone who can read terraform.tfstate can read this password.
# ==============================================================================
resource "random_password" "generated" {
  length  = 24
  special = false
}

output "packer_password" {
  description = "Password for the packer account on both images"
  value       = random_password.generated.result
  sensitive   = true
}
