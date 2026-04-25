# Providers + backend + module call.
# Replace PROJECT_NAME and the backend bucket/namespace/key with project-specific
# values. Auth0 and GitHub are module options — toggle with enable_auth0 /
# enable_github and only configure those provider blocks when enabled.

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 7.12.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    # Add only if enable_auth0 = true:
    # auth0  = { source = "auth0/auth0",         version = ">= 1.0.0" }
    # Add only if enable_github = true:
    # github = { source = "integrations/github", version = "~> 6.0" }
  }

  # Optional remote state in OCI Object Storage.
  # Create the bucket once, then uncomment.
  # backend "oci" {
  #   bucket    = "terraform-state"
  #   namespace = "YOUR_OS_NAMESPACE"
  #   key       = "PROJECT_NAME/terraform.tfstate"
  # }
}

provider "oci" {
  tenancy_ocid = var.TENANCY_OCID
  user_ocid    = var.USER_OCID
  fingerprint  = var.FINGERPRINT
  private_key  = local.oci_private_key
  region       = var.REGION
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}

# Required when enable_auth0 = true. If you leave both this provider block
# and the auth0 entry in required_providers commented out, terraform won't
# download the auth0 plugin. Forgetting this block while enable_auth0 = true
# fails plan with "provider not configured".
# provider "auth0" {
#   domain        = var.AUTH0_DOMAIN
#   client_id     = var.AUTH0_M2M_CLIENT_ID
#   client_secret = var.AUTH0_M2M_CLIENT_SECRET
# }

# Required when enable_github = true. Same caveat as auth0 — leaving both
# blocks commented skips the plugin download; forgetting this while
# enable_github = true fails plan with "provider not configured".
# provider "github" {
#   owner = var.GITHUB_OWNER
#   token = var.GITHUB_TOKEN
# }

module "infra" {
  source = "github.com/MMJLee/terraform-oci-free-tier"

  tenancy_ocid   = var.TENANCY_OCID
  region         = var.REGION
  ssh_public_key = local.ssh_public_key
  project_name   = "PROJECT_NAME"

  # Adjust shape — total OCPUs must be <= 4 and total memory <= 24GB
  instances = {
    app = {
      ocpus           = 4
      memory_gb       = 24
      block_volume_gb = 50
      extra_packages  = []
      behind_lb       = true
    }
  }

  # 0, 1, or 2 ATP databases. Remove keys you don't need.
  databases = {
    main = { display_name = "MainDB", db_name = "MAINDB" }
  }

  bucket_name = "PROJECT_NAME-backups"

  # --- Cloudflare LB + DNS + SSL ---
  enable_cloudflare    = true
  cloudflare_api_token = var.CLOUDFLARE_API_TOKEN
  cloudflare_zone_id   = var.CLOUDFLARE_ZONE_ID
  domain_name          = var.DOMAIN_NAME
  dns_records          = [var.DOMAIN_NAME, "app"]

  # --- Auth0 (uncomment to enable) ---
  # enable_auth0        = true
  # auth0_api_audience  = var.AUTH0_API_AUDIENCE
  # auth0_jwt_namespace = var.AUTH0_JWT_NAMESPACE
  # auth0_callback_urls = var.AUTH0_CALLBACK_URLS
  # auth0_admin_user_id = var.AUTH0_ADMIN_USER_ID

  # --- GitHub Actions secret sync (uncomment to enable) ---
  # Auto-syncs: OCI auth, SSH keys, Cloudflare, Auth0, per-instance <NAME>_IP,
  # per-database <KEY>_DB_OCID, vault, OS namespace. Pass `github_secrets` for
  # additional project-specific values.
  # enable_github           = true
  # github_owner            = var.GITHUB_OWNER
  # github_repo             = var.GITHUB_REPO
  # oci_user_ocid           = var.USER_OCID
  # oci_fingerprint         = var.FINGERPRINT
  # oci_private_key         = local.oci_private_key
  # ssh_private_key         = local.ssh_private_key
  # ip_address              = var.IP_ADDRESS
  # auth0_domain            = var.AUTH0_DOMAIN
  # auth0_client_id         = var.AUTH0_CLIENT_ID
  # auth0_client_secret     = var.AUTH0_CLIENT_SECRET
  # auth0_m2m_client_id     = var.AUTH0_M2M_CLIENT_ID
  # auth0_m2m_client_secret = var.AUTH0_M2M_CLIENT_SECRET
  # github_secrets = {
  #   # GOOGLE_CLIENT_ID = var.GOOGLE_CLIENT_ID
  # }
}
