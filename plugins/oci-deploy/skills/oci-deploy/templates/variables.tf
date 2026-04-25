# Variables declared by the calling project's root config. The core module
# owns infra resources — caller declares these and passes them through.
#
# Skill scaffolding rules:
#   - Always include the OCI Authentication block + the SSH key paths.
#   - Only include the Cloudflare / Auth0 / GitHub blocks if the user enabled
#     the matching addon module in main.tf. Variables for unused addons are
#     dead weight and clutter terraform.tfvars.

# --- OCI Authentication (always) ---
variable "TENANCY_OCID" { type = string }
variable "USER_OCID" { type = string }
variable "FINGERPRINT" { type = string }
variable "REGION" { type = string }
variable "IP_ADDRESS" {
  type        = string
  description = "Your public IP in CIDR form (e.g., 1.2.3.4/32) — used for direct SSH"
}

variable "OCI_PRIVATE_KEY_PATH" {
  type        = string
  description = "Path to OCI API private key PEM file"
}

variable "SSH_PUBLIC_KEY_PATH" {
  type        = string
  description = "Path to SSH public key file for instance access"
}

variable "SSH_PRIVATE_KEY_PATH" {
  type        = string
  description = "Path to SSH private key file (passed to github addon as ssh_private_key when used)"
}

locals {
  oci_private_key = file(var.OCI_PRIVATE_KEY_PATH)
  ssh_public_key  = file(var.SSH_PUBLIC_KEY_PATH)
  ssh_private_key = file(var.SSH_PRIVATE_KEY_PATH)
}

# --- Cloudflare addon (only when module "cloudflare" is invoked) ---
# variable "CLOUDFLARE_API_TOKEN" {
#   type      = string
#   sensitive = true
# }
#
# variable "CLOUDFLARE_ZONE_ID" {
#   type = string
# }
#
# variable "DOMAIN_NAME" {
#   type        = string
#   description = "Custom domain name (e.g., example.com)"
# }

# --- GitHub addon (only when module "github_secrets" is invoked) ---
# variable "GITHUB_OWNER" {
#   type        = string
#   description = "GitHub username or org that owns the repo"
# }
#
# variable "GITHUB_TOKEN" {
#   type        = string
#   sensitive   = true
#   description = "GitHub personal access token with repo scope (for setting Actions secrets)"
# }
#
# variable "GITHUB_REPO" {
#   type        = string
#   description = "GitHub repository name"
# }

# --- Auth0 addon (only when module "auth0" is invoked) ---
# variable "AUTH0_DOMAIN" { type = string }
#
# variable "AUTH0_CLIENT_ID" {
#   type      = string
#   sensitive = true
# }
#
# variable "AUTH0_CLIENT_SECRET" {
#   type      = string
#   sensitive = true
# }
#
# variable "AUTH0_M2M_CLIENT_ID" {
#   type      = string
#   sensitive = true
# }
#
# variable "AUTH0_M2M_CLIENT_SECRET" {
#   type      = string
#   sensitive = true
# }
#
# variable "AUTH0_API_AUDIENCE" {
#   type        = string
#   description = "Auth0 API identifier (e.g., https://api.example.com). Used as audience claim."
# }
#
# variable "AUTH0_JWT_NAMESPACE" {
#   type        = string
#   description = "Namespace prefix for custom claims (e.g., https://app.example.com). Must match what your backend reads."
# }
#
# variable "AUTH0_ADMIN_USER_ID" {
#   type        = string
#   default     = ""
#   description = "Auth0 user_id (e.g., auth0|abc123) auto-assigned the admin role. Empty to skip."
# }
#
# variable "AUTH0_CALLBACK_URLS" {
#   type        = list(string)
#   default     = []
#   description = "Allowed callback URLs for the SPA client (e.g., [\"https://app.example.com\", \"http://localhost:5173\"])"
# }
