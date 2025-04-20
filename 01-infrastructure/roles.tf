# IAM Member: Firestore Access
# Grants the Firestore user role to the specified service account for the project.
resource "google_project_iam_member" "flask_firestore_access" {
  project = local.credentials.project_id                      # Specifies the project ID from local credentials.
  role    = "roles/datastore.user"                            # Role assigned to the member, allowing Firestore access.
  member  = "serviceAccount:${local.service_account_email}"   # Service account email receiving the role.
}
