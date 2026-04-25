# Re-exports useful module outputs plus a few convenience values.
# Add or remove outputs depending on what your CI/CD or fetch_secrets.sh needs.

output "load_balancer_public_ip" {
  value = module.infra.load_balancer_ip
}

output "arm_instance_public_ip" {
  value = module.infra.instances["app"].public_ip
}

output "arm_instance_private_ip" {
  value = module.infra.instances["app"].private_ip
}

output "ssh_to_arm" {
  value = module.infra.ssh_commands["app"]
}

# Database outputs — adjust keys to match your `databases` map
output "main_db_ocid" {
  value = module.infra.database_ids["main"]
}

output "main_db_connection_urls" {
  value = module.infra.database_connection_urls["main"]
}

output "main_db_admin_password" {
  value     = module.infra.database_admin_passwords["main"]
  sensitive = true
}

output "db_region_host" {
  value = module.infra.db_region_host
}

# Vault
output "vault_ocid" {
  value = module.infra.vault_id
}

output "vault_crypto_endpoint" {
  value = module.infra.vault_crypto_endpoint
}

output "vault_master_key_id" {
  value = module.infra.vault_key_id
}

# Object Storage
output "os_namespace" {
  value = module.infra.os_namespace
}

# Domain
output "domain" {
  value = var.DOMAIN_NAME
}
