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

variable "neg_name" {
  type        = string
  description = "Name of NEG to find in defined zone(s)"
}

variable "additional_negs" {
  description = "You can pass aditional data source objects of NEG's which will be added to load_balancer"
  default     = null
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

variable "hostnames" {
  type        = list(string)
  description = "List of hostnames to route to backend created from named NEGs. Beware if you are using google_managed_tls - certificate will be created only for first entry in this list"
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
