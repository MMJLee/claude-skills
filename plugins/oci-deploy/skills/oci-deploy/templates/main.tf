# Providers + backend + module call.
# Replace PROJECT_NAME, DOMAIN_NAME, and the backend bucket/namespace/key
# values with project-specific ones. Add provider blocks for `github` and
# `auth0` only if you also include templates/github.tf or templates/auth0.tf.

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
    # Add only if using github.tf:
    # github = { source = "integrations/github", version = "~> 6.0" }
    # Add only if using auth0.tf:
    # auth0  = { source = "auth0/auth0",         version = ">= 1.0.0" }
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

# Uncomment if including github.tf
# provider "github" {
#   owner = var.GITHUB_OWNER
#   token = var.GITHUB_TOKEN
# }

# Uncomment if including auth0.tf
# provider "auth0" {
#   domain        = var.AUTH0_DOMAIN
#   client_id     = var.AUTH0_M2M_CLIENT_ID
#   client_secret = var.AUTH0_M2M_CLIENT_SECRET
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

  # Cloudflare LB + DNS + SSL
  enable_cloudflare    = true
  cloudflare_api_token = var.CLOUDFLARE_API_TOKEN
  cloudflare_zone_id   = var.CLOUDFLARE_ZONE_ID
  domain_name          = var.DOMAIN_NAME
  dns_records          = [var.DOMAIN_NAME, "app"]
}
