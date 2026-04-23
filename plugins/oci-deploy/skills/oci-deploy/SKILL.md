---
name: oci-deploy
description: "Scaffold and deploy OCI Always Free tier infrastructure. Use when the user wants to set up OCI infra, create a new project on OCI free tier, deploy to Oracle Cloud, or manage terraform-oci-free-tier module configuration."
---

# OCI Free Tier Deploy

Scaffold, configure, and deploy OCI Always Free tier infrastructure using the `terraform-oci-free-tier` module.

## Module Reference

Source: `github.com/MMJLee/terraform-oci-free-tier`

The module creates: VCN + subnets, 1+ ARM A1.Flex instances, 0-2 ATP databases, OCI Vault + KMS, optional Cloudflare LB/SSL, backup bucket, and free tier quotas.

### Instance config options

Each instance accepts: `ocpus`, `memory_gb`, `boot_volume_gb` (default 50), `block_volume_gb` (default 0), `app_port` (default 8080), `app_user` (default "opc"), `workspace_path` (default "/var/workspace"), `extra_packages` (list), `extra_cloud_init` (string), `behind_lb` (default true).

**Free tier limits:** 4 OCPU / 24GB RAM total across all instances, 200GB total storage, 2 ATP databases, 1 LB.

## Workflow

### Phase 1: Scaffold

Ask these questions ONE AT A TIME to configure the infrastructure:

1. **Project name** — used in resource display names and file naming
2. **Instance layout** — offer these options:
   - Single instance (4 OCPU / 24GB) — simplest, good for monoliths
   - Two instances (2+2 OCPU, 12+12GB) — e.g., app + worker
   - Four instances (1+1+1+1 OCPU, 6+6+6+6GB) — microservices
   - Custom split — let them specify
3. **For each instance** — name, extra packages needed, extra cloud-init commands, app port if not 8080, block volume size (or 0)
4. **Databases** — 0, 1, or 2 ATP instances. For each: a key name and display name.
5. **Cloudflare** — yes/no. If yes: domain name, which DNS records (root + subdomains), which instances go behind the LB.
6. **Backup bucket** — name or skip
7. **Additional providers** — Auth0, GitHub secrets sync, or other project-specific terraform? Note these are NOT part of the module — they go in separate .tf files alongside the module call.

After gathering answers, generate these files in a `terraform/` directory (or user's preferred path):

- `main.tf` — providers + backend + module call
- `variables.tf` — all required variables
- `outputs.tf` — re-exports of module outputs plus any project-specific outputs
- `terraform.tfvars.example` — template with placeholder values

If the user needs Auth0, GitHub secrets, or other provider-specific terraform, generate those as separate .tf files.

### Phase 2: Deploy

Guide through deployment step by step. **Always wait for user confirmation before running apply.**

1. `terraform init` — initialize providers and download module
2. `terraform plan` — show what will be created, summarize the key resources
3. Confirm with user before proceeding
4. `terraform apply` — run with user watching
5. Post-deploy verification:
   - Show instance IPs and SSH commands from outputs
   - Check if instances are reachable (SSH or curl health endpoint)
   - Remind about next steps (deploy app binary, run fetch_secrets.sh, etc.)

### Phase 3: Manage (on-demand)

Handle common operations when asked:

- **Add/remove instances** — update the instances map, plan, apply
- **Add/remove databases** — update the databases map
- **Enable/disable Cloudflare** — toggle and manage DNS
- **Destroy** — `terraform destroy` with confirmation
- **Import existing resources** — `terraform import` for resources created outside terraform
- **Show status** — `terraform output`, SSH commands, instance health

## Rules

- NEVER run `terraform apply` without showing the plan and getting user confirmation first
- NEVER hardcode secrets in generated files — always use variables with sensitive flag
- ALWAYS generate a .tfvars.example with placeholder values, not real credentials
- ALWAYS check that instance OCPU/memory totals stay within free tier (4 OCPU, 24GB)
- ALWAYS check total storage stays within 200GB (boot volumes + block volumes)
- If the user has an existing terraform setup, help migrate to the module rather than starting fresh
- Use the OCI CLI (`oci`) when available for resource lookups and verification
