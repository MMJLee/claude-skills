# Re-exports useful module outputs plus a few convenience values.
# Add or remove outputs depending on what your CI/CD or fetch_secrets.sh needs.
#
# Skill scaffolding rules:
#   - Core outputs always available via module.core.*
#   - Load balancer output only available if module "cloudflare" is invoked.
#   - Auth0 outputs only available if module "auth0" is invoked.
#     Don't scaffold outputs for addons the user didn't enable.

# --- Compute (always) ---

output "arm_instance_public_ip" {
  value = module.core.instances["app"].public_ip
}

output "arm_instance_private_ip" {
  value = module.core.instances["app"].private_ip
}

output "ssh_to_arm" {
  value = module.core.ssh_commands["app"]
}

# --- Database (adjust keys to match `databases` map; remove if no databases) ---

output "main_db_ocid" {
  value = module.core.database_ids["main"]
}

output "main_db_connection_urls" {
  value = module.core.database_connection_urls["main"]
}

output "main_db_admin_password" {
  value     = module.core.database_admin_passwords["main"]
  sensitive = true
}

output "db_region_host" {
  value = module.core.db_region_host
}

# --- Vault (always) ---

output "vault_ocid" {
  value = module.core.vault_id
}

output "vault_crypto_endpoint" {
  value = module.core.vault_crypto_endpoint
}

output "vault_master_key_id" {
  value = module.core.vault_key_id
}

# --- Object Storage (always) ---

output "os_namespace" {
  value = module.core.os_namespace
}

# --- Cloudflare addon outputs (only when module "cloudflare" is invoked) ---
# output "load_balancer_public_ip" {
#   value = module.cloudflare.load_balancer_ip
# }
#
# output "domain" {
#   value = var.DOMAIN_NAME
# }

# --- Auth0 addon outputs (only when module "auth0" is invoked) ---
# output "auth0_spa_client_id" {
#   value     = module.auth0.spa_client_id
#   sensitive = true
# }
#
# output "auth0_api_audience" {
#   value = module.auth0.api_audience
# }
