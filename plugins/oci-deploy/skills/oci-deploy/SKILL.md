---
name: oci-deploy
description: "Scaffold and deploy OCI Always Free tier infrastructure. Use when the user wants to set up OCI infra, create a new project on OCI free tier, deploy to Oracle Cloud, or manage terraform-oci-free-tier module configuration."
---

# OCI Free Tier Deploy

Scaffold, configure, and deploy OCI Always Free tier infrastructure using the `terraform-oci-free-tier` module.

## Module Reference

Source: `github.com/MMJLee/terraform-oci-free-tier`

The module creates: VCN + subnets, 1+ ARM A1.Flex instances, 0-2 ATP databases, OCI Vault + KMS, optional Object Storage bucket, and free tier quotas. It also has opt-in toggles for `enable_cloudflare` (LB + DNS + origin SSL), `enable_auth0` (SPA + M2M clients, API resource server, admin/user roles, post-login JWT action), and `enable_github` (Actions secret sync covering OCI auth, SSH keys, Cloudflare/Auth0 creds, and infrastructure outputs).

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
6. **Object storage bucket** — name or skip
7. **Auth0** — yes/no. If yes:
   - API audience (e.g., `https://api.example.com`) — used as the JWT `aud` claim
   - JWT custom-claim namespace (e.g., `https://app.example.com`) — must match what the backend reads
   - Allowed callback URLs (e.g., `["https://app.example.com", "http://localhost:5173"]`)
   - Auth0 user_id of the initial admin (optional, can be filled in after first login)
8. **GitHub Actions secret sync** — yes/no. If yes:
   - GitHub owner + repo
   - Confirm CI/CD will need a PAT with `repo` scope to be passed as `GITHUB_TOKEN`
   - Any project-specific secrets to add via `github_secrets = {...}` (e.g., `GOOGLE_CLIENT_ID`, `GH_TOKEN` for `gh` CLI auth in workflows)
   - The module auto-syncs OCI auth, SSH keys, Cloudflare/Auth0 creds, and infrastructure outputs (per-instance `<NAME>_IP`, per-database `<KEY>_DB_OCID`, vault, OS namespace).

After gathering answers, generate these files in a `terraform/` directory (or user's preferred path). Use the files in `templates/` as a starting point — copy them and substitute the answers from above:

- `main.tf` — providers + backend + module call (template: `templates/main.tf`)
- `variables.tf` — all required variables (template: `templates/variables.tf`)
- `outputs.tf` — re-exports of module outputs plus project-specific outputs (template: `templates/outputs.tf`)
- `terraform.tfvars.example` — placeholder values (template: `templates/terraform.tfvars.example`)

Auth0 and GitHub secret sync live INSIDE the module — toggle with `enable_auth0 = true` / `enable_github = true` in the module call. The template `main.tf` has both blocks pre-written and commented out — uncomment them, plus the matching `required_providers` and `provider` blocks. Variables for both are already declared in `templates/variables.tf`.

The templates contain `PROJECT_NAME` placeholders and inline comments calling out what needs editing — substitute project-specific values when copying.

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
- **Toggle Cloudflare / Auth0 / GitHub sync** — flip `enable_cloudflare` / `enable_auth0` / `enable_github`. When turning a feature OFF, the matching resources will be destroyed on apply — confirm with the user before proceeding.
- **Add a GitHub Actions secret** — append to the `github_secrets = {...}` map and apply. The module merges it on top of the auto-derived secrets.
- **Rotate a credential** — update the relevant variable (e.g., `AUTH0_M2M_CLIENT_SECRET`), apply. The module's `github_actions_secret` will detect drift and update GitHub.
- **Destroy** — `terraform destroy` with confirmation. Note: this also destroys every secret managed by `github_actions_secret` and every Auth0 client/role — CI/CD won't run again until `terraform apply`.
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
