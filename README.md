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

1. **Scaffold** — asks about your project (instance layout, databases, Cloudflare, etc.) and generates terraform files
2. **Deploy** — walks through `terraform init` / `plan` / `apply` with confirmation at each step
3. **Manage** — add/remove instances or databases, enable Cloudflare, import resources, destroy

**Example:**

```
> /oci-deploy
# Asks: project name, instance layout (1x4CPU or 4x1CPU, etc.),
# databases (0-2), Cloudflare yes/no, backup bucket
# Then generates main.tf, variables.tf, outputs.tf, terraform.tfvars.example
# and guides you through deployment
```

## Adding new skills

1. Create a folder under `plugins/<skill-name>/`
2. Add `.claude-plugin/plugin.json` with name, version, description
3. Add `skills/<skill-name>/SKILL.md` with frontmatter and instructions
4. Update `.claude-plugin/marketplace.json` to include the new plugin
5. Commit and push — users run `/reload-plugins` to pick it up
