variable "project" {
  description = "Project ID"
  type        = string
}

variable "region" {
  description = "GCP region where we will look for NEGs"
  type        = string
}

variable "zone" {
  description = "GCP zone where we will look for NEGs - optional parameter, if not set, the we will automatically search in all zones in region"
  type        = string
  default     = null
}

variable "name" {
  type        = string
  description = "Instance name"
  default     = "default_value"
}

variable "self_signed_tls" {
  type        = bool
  description = "If true, creates self-signed TLS cert"
  default     = false
}

variable "google_managed_tls" {
  type        = bool
  description = "If true, creates Google-managed TLS cert"
  default     = false
}

variable "keys_alg" {
  type        = string
  description = "Algorithm used for private keys"
  default     = "RSA"
}

variable "keys_valid_period" {
  type        = number
  description = "Validation period of the self signed key"
  default     = 29200
}

variable "default_network_name" {
  type        = string
  description = "Default firewall network name, used to place a default fw allowing google's default health checks. Leave blank if you use GKE ingress-provisioned LB (now deprecated)"
  default     = "default"
}

variable "services" {
  type = list(object({
    name                      = string
    type                      = string
    bucket_name               = optional(string)
    location                  = optional(string)
    zone                      = optional(string)
    additional_negs           = optional(list(string))
    timeout_sec               = optional(number)
    check_interval_sec        = optional(number)
    healthy_threshold         = optional(number)
    unhealthy_threshold       = optional(number)
    http_backend_protocol     = optional(string)
    http_backend_timeout      = optional(string)
    health_check_request_path = optional(string)
    enable_cdn                = optional(bool)
  }))
  description = "List of services: cloudrun, neg, bucket, ... to be used in the map"
}
variable "url_map" {
  type = map(object({
    hostnames       = list(string)
    default_service = string
    path_rules = optional(list(object({
      paths   = list(string)
      service = string
    })))
    route_rules = optional(list(object({
      service = string
      paths = list(object({
        name                    = string
        priority                = number
        query_parameter_matches = optional(string)
        url_rewrite             = optional(string)
      }))
    })))
  }))
  description = "Url map setup"

  validation {
    condition     = !(contains(keys(var.url_map), "route_rules") && contains(keys(var.url_map), "path_rules"))
    error_message = "Both route_rules and path_rules cannot be set at the same time. Only one of them should be used."
  }
}
variable "http_backend_timeout" {
  type        = string
  description = "Time of http request timeout (in seconds)"
  default     = "30"
}

variable "http_backend_protocol" {
  type        = string
  description = "HTTP backend protocol, one of: HTTP/HTTP2"
  default     = "HTTP"
  validation {
    condition     = can(regex("HTTP(2?)", var.http_backend_protocol))
    error_message = "The http_backend_protocol value must be HTTP or HTTP2."
  }
}

variable "backend_bucket_location" {
  type        = string
  description = "GCS location(https://cloud.google.com/storage/docs/locations) of bucket where invalid requests are routed."
  default     = "EUROPE-WEST3"
}

variable "managed_certificate_name" {
  type        = string
  description = "Name of Google-managed certificate. Useful when migrating from Ingress-provisioned load balancer"
  default     = null
}

variable "allow_non_tls_frontend" {
  type        = string
  description = "If true, enables port 80 frontend - creates non-TLS (http://) variant of LB"
  default     = false
}

variable "unhealthy_threshold" {
  description = "A so-far healthy instance will be marked unhealthy after this many consecutive failures. The default value is 2."
  type        = number
  default     = 2
}

variable "healthy_threshold" {
  description = "A so-far unhealthy instance will be marked healthy after this many consecutive successes. The default value is 2."
  type        = number
  default     = 2
}

variable "custom_health_check_ports" {
  description = "Custom ports for GCE health checks, not needed unless your services are not in 30000-32767 or 3000, 5000"
  default     = []
  type        = list(string)
}

variable "check_interval_sec" {
  description = "How often (in seconds) to send a health check. The default value is 5 seconds."
  type        = number
  default     = 5
}

variable "timeout_sec" {
  description = "How long (in seconds) to wait before claiming failure. The default value is 5 seconds. It is invalid for timeout_sec to have greater value than check_interval_sec."
  type        = number
  default     = 5
}

variable "health_check_request_path" {
  type        = string
  description = "Health checked path (URN)"
  default     = "/healthz"
}

variable "certificate" {
  type        = string
  description = "The certificate in PEM format. The certificate chain must be no greater than 5 certs long. The chain must include at least one intermediate cert. Note: This property is sensitive and will not be displayed in the plan."
  default     = null
  sensitive   = true
}

variable "private_key" {
  type        = string
  description = "The write-only private key in PEM format. Note: This property is sensitive and will not be displayed in the plan."
  default     = null
  sensitive   = true
}

variable "log_config_sample_rate" {
  type        = string
  description = "The value of the field must be in [0, 1]. This configures the sampling rate of requests to the load balancer where 1.0 means all logged requests are reported and 0.0 means no logged requests are reported. The default value is 1.0."
  default     = "1.0"
}

variable "create_logging_sink_bucket" {
  type        = bool
  description = "If true, creates bucket and set up logging sink"
  default     = false
}

variable "logging_sink_bucket_retency" {
  type        = number
  description = "Number of days after which log files are deleted from bucket"
  default     = 730
}

variable "mask_metrics_endpoint" {
  type        = bool
  description = "If set, requests /metrics will be sent to default backend"
  default     = false
}

variable "dont_use_dns_names_in_certificate" {
  description = "Due to backward compatibility, TLS setup can omit setup of dns_names in self signed certificate"
  type        = bool
  default     = false
}

variable "iap_setup" {
  description = "Service setup for IAP, overwrites default_iap_setup if used"
  type = map(object({
    oauth2_client_id     = string
    oauth2_client_secret = string
  }))
  default = {}
}

variable "default_iap_setup" {
  description = "In case you use the same IAP setup for all backends"
  type = object({
    oauth2_client_id     = string
    oauth2_client_secret = string
  })
  default = null
}

variable "random_suffix_size" {
  description = "Size of random suffix"
  type        = number
  default     = 8
}

variable "custom_url_map_name" {
  description = "Custom name for URL map name used instead of lb-var.name"
  type        = string
  default     = ""
}

variable "custom_target_http_proxy_name" {
  description = "Custom name for HTTP proxy name used instead of non-tls-proxy-"
  type        = string
  default     = ""
}

variable "use_random_suffix_for_network_endpoint_group" {
  description = "If true, uses random suffix for NEG name"
  type        = bool
  default     = true
}

variable "non_tls_global_forwarding_rule_name" {
  description = "Global non tls forwarding rule name, if set, changes name of non-tls forwarding rule"
  type        = string
  default     = ""
}
