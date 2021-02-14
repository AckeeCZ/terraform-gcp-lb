# Terraform GKE native container LB module

Terraform module for provisioning of GCP LB on top of precreated named NEG passed as parameter to this module.

## Usage

### HTTPS Load-balancer with self-signed certificate and Cloudflare DNS record creation:
```hcl
data "cloudflare_zones" "ackee_cz" {
  filter {
    name = "ackee.cz"
  }
}

module "api-unicorn" {
  source          = "../terraform-gcp-lb"
  name            = "api-unicorn"
  project         = var.project
  region          = var.region
  neg_name        = "ackee-api-unicorn"
  hostname        = "api-unicorn.ackee.cz"
  self_signed_tls = true
}

resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zones.ackee_cz.zones[0].id
  name    = "api-unicorn"
  value   = module.api-unicorn.ip_address
  type    = "A"
  ttl     = 1
  proxied = true
}
```
If NEG named `ackee-api-unicorn` exists and CF is set to "SSL:Full" you should have working app now on https://api-unicorn.ackee.cz

### HTTPS Load-balancer with Google-managed certificate and Cloudflare DNS record creation:

```hcl
data "cloudflare_zones" "ackee_cz" {
  filter {
    name = "ackee.cz"
  }
}

module "api-unicorn" {
  source             = "../terraform-gcp-lb"
  name               = "api-unicorn"
  project            = var.project
  region             = var.region
  neg_name           = "ackee-api-unicorn"
  hostname           = "api-unicorn.ackee.cz"
  google_managed_tls = true
}

resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zones.ackee_cz.zones[0].id
  name    = "api-unicorn"
  value   = module.api-unicorn.ip_address
  type    = "A"
  ttl     = 1
  proxied = false
}
```
If NEG named `ackee-api-unicorn` exists you should have working app now on https://api-unicorn.ackee.cz

### HTTPS Load-balancer with preexisting NEG, Google-managed certificate and Cloudflare DNS record creation:

```hcl
data "google_compute_network_endpoint_group" "old_neg" {
  name  = "k8s1-aab5af95-production-ackee-unicorn-80-bafd3c69"
  zone  = "europe-west3-c"
  count = 1
}

data "cloudflare_zones" "ackee_cz" {
  filter {
    name = "ackee.cz"
  }
}

module "api-unicorn" {
  source             = "../terraform-gcp-lb"
  name               = "api-unicorn"
  project            = var.project
  region             = var.region
  neg_name           = "ackee-api-unicorn"
  hostname           = "api-unicorn.ackee.cz"
  additional_negs    = data.google_compute_network_endpoint_group.old_neg
  google_managed_tls = true
}

resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zones.ackee_cz.zones[0].id
  name    = "api-unicorn"
  value   = module.api-unicorn.ip_address
  type    = "A"
  ttl     = 1
  proxied = false
}
```

If we pass `data.google_compute_network_endpoint_group` resource as value for `additional_negs` parameter, then our new load-balancer
gets created from new named NEG's auto discovered by name in `neg_name` parameter and from NEG's from `additional_negs` parameter - 
this should be used when migrating from old setup, so we balance to both new and old application.

## Creation of NEG's is not automatic!

**BEWARE: Network Endpoint Groups REFERENCED BY THIS MODULE MUST EXIST BEFORE YOU USE THIS MODULE, OTHERWISE IT WILL FAIL WITH ERROR SIMILIAR TO:**
```
Error: Required attribute is not set

  on ../load-balancer.tf line 68, in resource "google_compute_backend_service" "cn_lb":
  68: resource "google_compute_backend_service" "cn_lb" {
```
Also note, that purging app (typically with `helm delete`) does not automatically cleanup existing NEGs

## Before you do anything in this module

Install pre-commit hooks by running following commands:

```shell script
brew install pre-commit
pre-commit install
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| google | n/a |
| google-beta | n/a |
| random | n/a |
| tls | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_negs | You can pass aditional data source objects of NEG's which will be added to load\_balancer | `any` | `null` | no |
| backend\_bucket\_location | GCS location(https://cloud.google.com/storage/docs/locations) of bucket where invalid requests are routed. | `string` | `"EUROPE-WEST3"` | no |
| default\_network\_name | Default firewall network name, used to place a default fw allowing google's default health checks. Leave blank if you use GKE ingress-provisioned LB (now deprecated) | `string` | `"default"` | no |
| google\_managed\_tls | If true, creates Google-managed TLS cert | `bool` | `false` | no |
| hostname | Hostname to route to backend created from named NEGs | `string` | n/a | yes |
| http\_backend\_protocol | HTTP backend protocol, one of: HTTP/HTTP2 | `string` | `"HTTP"` | no |
| http\_backend\_timeout | Time of http request timeout (in seconds) | `string` | `"30"` | no |
| keys\_alg | Algorithm used for private keys | `string` | `"RSA"` | no |
| keys\_valid\_period | Validation period of the self signed key | `number` | `29200` | no |
| name | Instance name | `string` | `"default_value"` | no |
| neg\_name | Name of NEG to find in defined zone(s) | `string` | n/a | yes |
| project | Project ID | `string` | n/a | yes |
| region | GCP region where we will look for NEGs | `string` | n/a | yes |
| self\_signed\_tls | If true, creates self-signed TLS cert | `bool` | `false` | no |
| zone | GCP zone where we will look for NEGs - optional parameter, if not set, the we will automatically search in all zones in region | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| ip\_address | IP address |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
