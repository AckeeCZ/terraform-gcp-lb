# Terraform GCP HTTP(S) Load Balancing 

Terraform module for provisioning of GCP LB on top of precreated named NEGs, Cloud Run services and GCS buckets passed as parameter to this module.

## Usage

### HTTPS Load-balancer with self-signed certificate and Cloudflare DNS record creation:
```hcl
data "cloudflare_zones" "ackee_cz" {
  filter {
    name = "ackee.cz"
  }
}

resource "google_storage_bucket" "test" {
  name                        = "test-randompostfix-98582341"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  website {
    main_page_suffix = "index.html"
  }
}

module "api_unicorn" {
  source          = "git::ssh://git@gitlab.ack.ee/Infra/tf-module/terraform-gcp-lb.git?ref=master"
  name            = "main-${var.project}-${var.namespace}"
  project         = var.project
  region          = var.region
  self_signed_tls = true
  negs = {
    "ackee-api-unicorn" : {
      hostnames             = ["api-unicorn.ackee.cz", "api-unicorn2.ackee.cz"]
      zone                  = var.zone
      http_backend_protocol = "HTTP"
    }
  }
  buckets = {
    "${google_storage_bucket.test.name}" : {
      hostnames             = ["test.ackee.cz"]
    }
  }
  services = {
    cloud-run-service = {
      hostnames = ["cloud-run-service.ackee.cz"]
    }
  }
}

resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zones.ackee_cz.zones[0].id
  name    = "api-unicorn"
  value   = module.api_unicorn.ip_address
  type    = "A"
  ttl     = 1
  proxied = true
}
```
If NEG named `ackee-api-unicorn` exists and CF is set to "SSL:Full" you should have working app now on https://api-unicorn.ackee.cz and https://api-unicorn2.ackee.cz

### HTTPS Load-balancer with Google-managed certificate and Cloudflare DNS record creation:

```hcl
data "cloudflare_zones" "ackee_cz" {
  filter {
    name = "ackee.cz"
  }
}

module "api_unicorn" {
  source             = "git::ssh://git@gitlab.ack.ee/Infra/tf-module/terraform-gcp-lb.git?ref=master"
  name               = "main-${var.project}-${var.namespace}"
  project            = var.project
  region             = var.region
  google_managed_tls = true
  negs = {
    "ackee-api-unicorn" : {
      hostnames             = ["api-unicorn.ackee.cz"]
      zone                  = var.zone
      http_backend_protocol = "HTTP"
    }
  }
}

resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zones.ackee_cz.zones[0].id
  name    = "api-unicorn"
  value   = module.api_unicorn.ip_address
  type    = "A"
  ttl     = 1
  proxied = false
}
```
If NEG named `ackee-api-unicorn` exists you should have working app now on https://api-unicorn.ackee.cz
**Beware**: If you use more then one hostname with Google-managed certificate, only one certificate, with first hostname in list, will be created. 

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

module "api_unicorn" {
  source             = "git::ssh://git@gitlab.ack.ee/Infra/tf-module/terraform-gcp-lb.git?ref=master"
  name               = "main-${var.project}-${var.namespace}"
  project            = var.project
  region             = var.region
  google_managed_tls = true
  negs = {
    "ackee-api-unicorn" : {
      hostnames             = ["api-unicorn.ackee.cz"]
      additional_negs       = [data.google_compute_network_endpoint_group.old_neg]
      zone                  = var.zone
      http_backend_protocol = "HTTP"
    }
  }
}

resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zones.ackee_cz.zones[0].id
  name    = "api-unicorn"
  value   = module.api_unicorn.ip_address
  type    = "A"
  ttl     = 1
  proxied = false
}
```

If we pass `data.google_compute_network_endpoint_group` resource as value for `additional_negs` parameter, then our new load-balancer
gets created from new named NEG's auto discovered by name in `neg_name` parameter and from NEG's from `additional_negs` parameter - 
this should be used when migrating from old setup, so we balance to both new and old application.

### HTTPS Load-balancer with pre-existing certificate (signed by external CA):
```hcl
module "api_unicorn" {
  source             = "git::ssh://git@gitlab.ack.ee/Infra/tf-module/terraform-gcp-lb.git?ref=master"
  name               = "main-${var.project}-${var.namespace}"
  project            = var.project
  region             = var.region
  negs = {
    "ackee-api-unicorn" : {
      hostnames             = ["api-unicorn.ackee.cz"]
      additional_negs       = [data.google_compute_network_endpoint_group.old_neg]
      zone                  = var.zone
      http_backend_protocol = "HTTP"
    }
  }
  certificate = file("${path.root}/tls/certificate_chain.crt")
  private_key = file("${path.root}/tls/private.key")
}
```
It is recommended to use some secure storage (eg. Vault) and pass value from here, rather then saving plaintext private key into git repo

## Creation of NEG's is not automatic!

**BEWARE: Network Endpoint Groups REFERENCED BY THIS MODULE MUST EXIST BEFORE YOU USE THIS MODULE, OTHERWISE IT WILL FAIL WITH ERROR SIMILIAR TO:**
```
Error: Required attribute is not set

  on ../load-balancer.tf line 68, in resource "google_compute_backend_service" "cn_lb":
  68: resource "google_compute_backend_service" "cn_lb" {
```
Also note, that purging app (typically with `helm delete`) does not automatically cleanup existing NEGs

## Using example

Because of chicken-egg mentioned in previous section, it is also not so easy to use provider example code. Running just `terraform apply` will fail
on similiar error. Workaround is to create testing NEG first and load balancer above it in next step.
```
terraform apply -target=google_compute_network_endpoint_group.neg
terraform apply
```

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_compute_backend_service.app_backend](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_backend_service) | resource |
| [google-beta_google_compute_backend_service.cloudrun](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_backend_service) | resource |
| [google-beta_google_compute_global_forwarding_rule.external_signed](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_forwarding_rule) | resource |
| [google-beta_google_compute_global_forwarding_rule.google_managed](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_forwarding_rule) | resource |
| [google-beta_google_compute_global_forwarding_rule.self_signed](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_forwarding_rule) | resource |
| [google_compute_backend_bucket.bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_bucket) | resource |
| [google_compute_backend_bucket.cn_lb](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_bucket) | resource |
| [google_compute_firewall.gcp_hc_ip_allow](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_global_address.gca](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_global_forwarding_rule.non_tls](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_health_check.cn_lb](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_managed_ssl_certificate.gcs_certs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) | resource |
| [google_compute_region_network_endpoint_group.cloudrun_neg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_endpoint_group) | resource |
| [google_compute_ssl_certificate.external_certs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_certificate) | resource |
| [google_compute_ssl_certificate.gcs_certs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_certificate) | resource |
| [google_compute_target_http_proxy.non_tls](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_http_proxy) | resource |
| [google_compute_target_https_proxy.external_signed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_target_https_proxy.google_managed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_target_https_proxy.self_signed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_url_map.cn_lb](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |
| [google_logging_project_sink.log_archive_sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink) | resource |
| [google_storage_bucket.cn_lb](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket.log_archive_sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_binding.log_archive_sink_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_binding) | resource |
| [random_id.external_certificate](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.random_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.web_lb_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.web_lb_cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [google_cloud_run_service.cloud_run_service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/cloud_run_service) | data source |
| [google_compute_network_endpoint_group.cn_lb](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network_endpoint_group) | data source |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_non_tls_frontend"></a> [allow\_non\_tls\_frontend](#input\_allow\_non\_tls\_frontend) | If true, enables port 80 frontend - creates non-TLS (http://) variant of LB | `string` | `false` | no |
| <a name="input_backend_bucket_location"></a> [backend\_bucket\_location](#input\_backend\_bucket\_location) | GCS location(https://cloud.google.com/storage/docs/locations) of bucket where invalid requests are routed. | `string` | `"EUROPE-WEST3"` | no |
| <a name="input_buckets"></a> [buckets](#input\_buckets) | Map of existing GCS buckets with related hostnames | `map(any)` | `{}` | no |
| <a name="input_certificate"></a> [certificate](#input\_certificate) | The certificate in PEM format. The certificate chain must be no greater than 5 certs long. The chain must include at least one intermediate cert. Note: This property is sensitive and will not be displayed in the plan. | `string` | `null` | no |
| <a name="input_check_interval_sec"></a> [check\_interval\_sec](#input\_check\_interval\_sec) | How often (in seconds) to send a health check. The default value is 5 seconds. | `number` | `5` | no |
| <a name="input_create_logging_sink_bucket"></a> [create\_logging\_sink\_bucket](#input\_create\_logging\_sink\_bucket) | If true, creates bucket and set up logging sink | `bool` | `false` | no |
| <a name="input_custom_health_check_ports"></a> [custom\_health\_check\_ports](#input\_custom\_health\_check\_ports) | Custom ports for GCE health checks, not needed unless your services are not in 30000-32767 or 3000, 5000 | `list(string)` | `[]` | no |
| <a name="input_default_iap_setup"></a> [default\_iap\_setup](#input\_default\_iap\_setup) | In case you use the same IAP setup for all backends | <pre>object({<br>    oauth2_client_id     = string<br>    oauth2_client_secret = string<br>  })</pre> | `null` | no |
| <a name="input_default_network_name"></a> [default\_network\_name](#input\_default\_network\_name) | Default firewall network name, used to place a default fw allowing google's default health checks. Leave blank if you use GKE ingress-provisioned LB (now deprecated) | `string` | `"default"` | no |
| <a name="input_dont_use_dns_names_in_certificate"></a> [dont\_use\_dns\_names\_in\_certificate](#input\_dont\_use\_dns\_names\_in\_certificate) | Due to backward compatibility, TLS setup can omit setup of dns\_names in self signed certificate | `bool` | `true` | no |
| <a name="input_google_managed_tls"></a> [google\_managed\_tls](#input\_google\_managed\_tls) | If true, creates Google-managed TLS cert | `bool` | `false` | no |
| <a name="input_health_check_request_path"></a> [health\_check\_request\_path](#input\_health\_check\_request\_path) | Health checked path (URN) | `string` | `"/healthz"` | no |
| <a name="input_healthy_threshold"></a> [healthy\_threshold](#input\_healthy\_threshold) | A so-far unhealthy instance will be marked healthy after this many consecutive successes. The default value is 2. | `number` | `2` | no |
| <a name="input_http_backend_protocol"></a> [http\_backend\_protocol](#input\_http\_backend\_protocol) | HTTP backend protocol, one of: HTTP/HTTP2 | `string` | `"HTTP"` | no |
| <a name="input_http_backend_timeout"></a> [http\_backend\_timeout](#input\_http\_backend\_timeout) | Time of http request timeout (in seconds) | `string` | `"30"` | no |
| <a name="input_iap_setup"></a> [iap\_setup](#input\_iap\_setup) | Service setup for IAP, overwrites default\_iap\_setup if used | <pre>map(object({<br>    oauth2_client_id     = string<br>    oauth2_client_secret = string<br>  }))</pre> | `{}` | no |
| <a name="input_keys_alg"></a> [keys\_alg](#input\_keys\_alg) | Algorithm used for private keys | `string` | `"RSA"` | no |
| <a name="input_keys_valid_period"></a> [keys\_valid\_period](#input\_keys\_valid\_period) | Validation period of the self signed key | `number` | `29200` | no |
| <a name="input_log_config_sample_rate"></a> [log\_config\_sample\_rate](#input\_log\_config\_sample\_rate) | The value of the field must be in [0, 1]. This configures the sampling rate of requests to the load balancer where 1.0 means all logged requests are reported and 0.0 means no logged requests are reported. The default value is 1.0. | `string` | `"1.0"` | no |
| <a name="input_logging_sink_bucket_retency"></a> [logging\_sink\_bucket\_retency](#input\_logging\_sink\_bucket\_retency) | Number of days after which log files are deleted from bucket | `number` | `730` | no |
| <a name="input_managed_certificate_name"></a> [managed\_certificate\_name](#input\_managed\_certificate\_name) | Name of Google-managed certificate. Useful when migrating from Ingress-provisioned load balancer | `string` | `null` | no |
| <a name="input_mask_metrics_endpoint"></a> [mask\_metrics\_endpoint](#input\_mask\_metrics\_endpoint) | If set, requests /metrics will be sent to default backend | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Instance name | `string` | `"default_value"` | no |
| <a name="input_negs"></a> [negs](#input\_negs) | Map of existing Network Endpoint Groups with related hostnames | `map(any)` | `{}` | no |
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | The write-only private key in PEM format. Note: This property is sensitive and will not be displayed in the plan. | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region where we will look for NEGs | `string` | n/a | yes |
| <a name="input_self_signed_tls"></a> [self\_signed\_tls](#input\_self\_signed\_tls) | If true, creates self-signed TLS cert | `bool` | `false` | no |
| <a name="input_services"></a> [services](#input\_services) | Map of Cloud Run services | `map(any)` | `{}` | no |
| <a name="input_timeout_sec"></a> [timeout\_sec](#input\_timeout\_sec) | How long (in seconds) to wait before claiming failure. The default value is 5 seconds. It is invalid for timeout\_sec to have greater value than check\_interval\_sec. | `number` | `5` | no |
| <a name="input_unhealthy_threshold"></a> [unhealthy\_threshold](#input\_unhealthy\_threshold) | A so-far healthy instance will be marked unhealthy after this many consecutive failures. The default value is 2. | `number` | `2` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | GCP zone where we will look for NEGs - optional parameter, if not set, the we will automatically search in all zones in region | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ip_address"></a> [ip\_address](#output\_ip\_address) | IP address |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
