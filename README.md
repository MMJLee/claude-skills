# claude-skills

Personal Claude Code skills marketplace.

## Install

```bash
# Add the marketplace (one-time)
claude plugin marketplace add MMJLee/claude-skills

# Install a skill
claude plugin install oci-deploy@claude-skills

# Reload to activate
/reload-plugins
```

## Skills

### oci-deploy

Scaffold and deploy OCI Always Free tier infrastructure using the [terraform-oci-free-tier](https://github.com/MMJLee/terraform-oci-free-tier) module.

**Invoke:** `/oci-deploy`

**What it does:**

1. **Scaffold** — asks about your project (instance layout, databases, optional Cloudflare/Auth0/GitHub addons) and generates terraform files
2. **Deploy** — walks through `terraform init` / `plan` / `apply` with confirmation at each step
3. **Manage** — add/remove instances or databases, add/remove addons (Cloudflare LB, Auth0 stack, GitHub secret sync), import resources, destroy

The terraform module is split into a **core** (always invoked) plus three **addon modules** (`cloudflare`, `auth0`, `github`) that the consumer invokes only when needed. Projects without an addon don't pay any provider tax for it — no stub provider blocks, no transitive plugin init.

**Example:**

```
> /oci-deploy
# Asks: project name, instance layout (1x4CPU or 4x1CPU, etc.),
# databases (0-2), backup bucket, Cloudflare addon (y/n), Auth0 addon (y/n),
# GitHub secret sync addon (y/n)
# Then generates main.tf, variables.tf, outputs.tf, terraform.tfvars.example
# (with only the providers/vars/module blocks for addons you said yes to)
# and guides you through deployment
```

## Adding new skills

1. Create a folder under `plugins/<skill-name>/`
2. Add `.claude-plugin/plugin.json` with name, version, description
3. Add `skills/<skill-name>/SKILL.md` with frontmatter and instructions
4. Update `.claude-plugin/marketplace.json` to include the new plugin
5. Commit and push — users run `/reload-plugins` to pick it up
