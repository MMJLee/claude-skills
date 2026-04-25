---
name: oci-deploy
description: "Scaffold and deploy OCI Always Free tier infrastructure. Use when the user wants to set up OCI infra, create a new project on OCI free tier, deploy to Oracle Cloud, or manage terraform-oci-free-tier module configuration."
---

# OCI Free Tier Deploy

Scaffold, configure, and deploy OCI Always Free tier infrastructure using the `terraform-oci-free-tier` module.

## Module Reference

Source: `github.com/MMJLee/terraform-oci-free-tier`

The module is split into a **core** module + three **addon** modules. The consumer invokes core (always) plus only the addons they want — no `enable_*` flags.

- **Core** (`github.com/MMJLee/terraform-oci-free-tier`) — VCN + subnets, 1+ ARM A1.Flex instances, 0–2 ATP databases, OCI Vault + KMS, optional Object Storage bucket, free tier quotas. Required providers: `oci`, `random`.
- **Cloudflare addon** (`//modules/cloudflare`) — LB + DNS + origin SSL + Cloudflare-IP NSG. Required providers: `oci`, `cloudflare`, `tls`.
- **Auth0 addon** (`//modules/auth0`) — SPA + M2M clients, API resource server, admin/user roles, post-login JWT action. Required providers: `auth0`.
- **GitHub addon** (`//modules/github`) — auto-syncs OCI auth, SSH keys, Cloudflare/Auth0 creds, and infrastructure outputs (per-instance `<NAME>_IP`, per-database `<KEY>_DB_OCID`, vault, OS namespace) into a GitHub repo's Actions secrets. Required providers: `github`.

The big win of the addon-module shape: a project that doesn't need Cloudflare doesn't pay any provider tax for it — no `provider "cloudflare"` block, no transitive cloudflare init at plan time. Each addon's required_providers only kicks in when the consumer invokes it.

### Instance config options

Each instance in the core module's `instances` map accepts: `ocpus`, `memory_gb`, `boot_volume_gb` (default 50), `block_volume_gb` (default 0), `app_port` (default 8080), `app_user` (default "opc"), `workspace_path` (default "/var/workspace"), `extra_packages` (list), `extra_cloud_init` (string), `behind_lb` (default true).

**Free tier limits:** 4 OCPU / 24GB RAM total across all instances, 200GB total storage, 2 ATP databases, 1 LB (only if cloudflare addon used).

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
5. **Object storage bucket** — name or skip
6. **Cloudflare addon** — yes/no. If yes: domain name, Cloudflare zone ID, DNS records to create (root + subdomains), which instances go behind the LB.
7. **Auth0 addon** — yes/no. If yes:
   - API audience (e.g., `https://api.example.com`) — used as the JWT `aud` claim
   - JWT custom-claim namespace (e.g., `https://app.example.com`) — must match what the backend reads
   - Allowed callback URLs (e.g., `["https://app.example.com", "http://localhost:5173"]`)
   - Auth0 user_id of the initial admin (optional, can be filled in after first login)
8. **GitHub Actions secret sync addon** — yes/no. If yes:
   - GitHub owner + repo
   - Confirm CI/CD will need a PAT with `repo` scope to be passed as `GITHUB_TOKEN`
   - Any project-specific secrets to add via `extra_secrets = {...}` (e.g., `GOOGLE_CLIENT_ID`, `GH_TOKEN` for `gh` CLI auth in workflows)

After gathering answers, generate these files in a `terraform/` directory (or user's preferred path). Use the files in `templates/` as a starting point — copy them and substitute the answers from above:

- `main.tf` — providers + backend + module calls (template: `templates/main.tf`)
- `variables.tf` — required variables (template: `templates/variables.tf`)
- `outputs.tf` — re-exports of module outputs plus project-specific outputs (template: `templates/outputs.tf`)
- `terraform.tfvars.example` — placeholder values (template: `templates/terraform.tfvars.example`)

**Generation rules:**

1. Always include the `module "core"` call with the core inputs (instances, databases, bucket_name).
2. **Only include the providers, variables, and `module "<addon>"` blocks for addons the user said yes to.** Do NOT scaffold cloudflare/auth0/github stubs "just in case" — that's the whole point of Path B. If they say no to cloudflare, the generated `main.tf` should have no `provider "cloudflare"` block, no `cloudflare = ...` in `required_providers`, and no `module "cloudflare" {}` call.
3. The cloudflare addon needs `vcn_id`, `public_subnet_id`, `instance_private_ips`, and an `instances` map filtered to the ones with `behind_lb = true`. Wire from `module.core.vcn_id`, `module.core.public_subnet_id`, and `module.core.instances`.
4. The github addon needs vault + namespace + per-instance + per-database from `module.core.*`. The template shows the full wiring.
5. The auth0 addon is self-contained — no inputs from `module.core`.

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

- **Add/remove instances** — update the `instances` map on `module.core`, plan, apply
- **Add/remove databases** — update the `databases` map on `module.core`
- **Add an addon to an existing project** — append the matching `module "<addon>"` block, the matching provider config, and the matching `required_providers` entry. Also add any new variables. Then plan/apply.
- **Remove an addon** — delete the `module "<addon>"` block, the `provider "<X>"` config, and the `required_providers` entry. Plan will show resources being destroyed; confirm with the user before applying.
- **Add a GitHub Actions secret** — append to the github addon's `extra_secrets = {...}` map and apply. The module merges it on top of the auto-derived secrets.
- **Rotate a credential** — update the relevant variable (e.g., `AUTH0_M2M_CLIENT_SECRET`), apply. The github addon's `github_actions_secret` will detect drift and update GitHub.
- **Destroy** — `terraform destroy` with confirmation. Note: this also destroys every secret managed by the github addon and every Auth0 client/role — CI/CD won't run again until `terraform apply`.
- **Import existing resources** — `terraform import` for resources created outside terraform
- **Show status** — `terraform output`, SSH commands, instance health

### Migrating from `enable_*` flags

If the user has an existing project pinned to a pre-Path-B SHA of the module (i.e., `enable_cloudflare = true` etc. on a single `module "infra" {}` call), help them migrate by:

1. Bumping the source ref to the latest commit (post-Path-B refactor)
2. Splitting the single `module "infra"` call into `module "core"` (just the core inputs) plus separate `module "cloudflare" {}` / `module "auth0" {}` / `module "github_secrets" {}` calls for whichever addons were enabled
3. Moving provider configurations outside the `module` blocks — only keep providers for addons that are still invoked
4. Updating any output references from `module.infra.*` to `module.core.*` (or to the addon module for `load_balancer_ip` and auth0 outputs)

The README on the upstream module has a migration table.

## Rules

- NEVER run `terraform apply` without showing the plan and getting user confirmation first
- NEVER hardcode secrets in generated files — always use variables with sensitive flag
- ALWAYS generate a .tfvars.example with placeholder values, not real credentials
- ALWAYS check that instance OCPU/memory totals stay within free tier (4 OCPU, 24GB)
- ALWAYS check total storage stays within 200GB (boot volumes + block volumes)
- NEVER scaffold provider blocks or addon module calls for features the user didn't enable — leaving them out is the point of the addon-module shape
- If the user has an existing terraform setup using `enable_*` flags, help them migrate to the new addon-module shape rather than starting fresh
- Use the OCI CLI (`oci`) when available for resource lookups and verification
