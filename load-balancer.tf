locals {
  zone_count    = length(data.google_compute_zones.available.names)
  random_suffix = random_string.random_suffix.result
  // this can be expanded to support other NEGs for migration purposes later
  backends                 = var.additional_negs != null ? concat(var.additional_negs, data.google_compute_network_endpoint_group.cn_lb) : data.google_compute_network_endpoint_group.cn_lb
  managed_certificate_name = var.managed_certificate_name != null ? var.managed_certificate_name : "${var.name}-cert-managed"
}

data "google_compute_zones" "available" {
  project = var.project
  region  = var.region
}

data "google_compute_network_endpoint_group" "cn_lb" {
  name  = var.neg_name
  zone  = var.zone != null ? var.zone : data.google_compute_zones.available.names[count.index]
  count = local.zone_count
}

resource "google_compute_backend_bucket" "cn_lb" {
  name        = "${var.project}-l7-default-backend-${local.random_suffix}"
  bucket_name = google_storage_bucket.cn_lb.name
  enable_cdn  = true
}

resource "google_compute_firewall" "gcp_hc_ip_allow" {
  name    = "gcp-healthchecks-ip-allow-${local.random_suffix}"
  network = var.default_network_name

  allow {
    protocol = "tcp"
    ports    = ["30000-32767", "3000", "5000"]
  }

  target_tags = ["k8s"]

  # GCP health check source ranges, see https://cloud.google.com/load-balancing/docs/health-checks
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
}

resource "google_storage_bucket" "cn_lb" {
  name     = "${var.project}-l7-default-backend-${local.random_suffix}"
  location = var.backend_bucket_location
}

resource "google_compute_health_check" "cn_lb" {
  name = "health-check-${local.random_suffix}"

  dynamic "http_health_check" {
    for_each = var.http_backend_protocol == "HTTP" ? [1] : []
    content {
      port_specification = "USE_SERVING_PORT"
      request_path       = "/healthz"
    }
  }
  dynamic "http2_health_check" {
    for_each = var.http_backend_protocol == "HTTP2" ? [1] : []
    content {
      port_specification = "USE_SERVING_PORT"
      request_path       = "/healthz"
    }
  }

}

resource "google_compute_backend_service" "cn_lb" {
  provider = google-beta

  name                  = "backend-${local.random_suffix}"
  health_checks         = [google_compute_health_check.cn_lb.id]
  load_balancing_scheme = "EXTERNAL"
  protocol              = var.http_backend_protocol
  timeout_sec           = var.http_backend_timeout

  dynamic "backend" {
    for_each = local.backends
    content {
      group          = backend.value.id
      balancing_mode = "RATE"
      max_rate       = 1
    }
  }
}

resource "google_compute_url_map" "cn_lb" {
  name            = "named-neg-lb-${var.name}-${local.random_suffix}"
  default_service = google_compute_backend_bucket.cn_lb.id

  host_rule {
    hosts        = [var.hostname]
    path_matcher = "primary"
  }

  path_matcher {
    name            = "primary"
    default_service = google_compute_backend_service.cn_lb.id
  }
}

// self-signed certificate variant

resource "google_compute_target_https_proxy" "self_signed" {
  name    = "http-proxy-${local.random_suffix}"
  url_map = google_compute_url_map.cn_lb.id

  ssl_certificates = [google_compute_ssl_certificate.gcs_certs[0].self_link]
  count            = var.self_signed_tls ? 1 : 0
}

resource "google_compute_global_forwarding_rule" "self_signed" {
  provider   = google-beta
  name       = "fw-rule-${local.random_suffix}"
  target     = google_compute_target_https_proxy.self_signed[0].id
  ip_address = google_compute_global_address.gca.address
  port_range = "443"
  count      = var.self_signed_tls ? 1 : 0
}

// Google-managed certificate variant

resource "google_compute_target_https_proxy" "google_managed" {
  name    = "http-proxy-${local.random_suffix}"
  url_map = google_compute_url_map.cn_lb.id

  ssl_certificates = [google_compute_managed_ssl_certificate.gcs_certs[0].self_link]
  count            = var.google_managed_tls ? 1 : 0
}

resource "google_compute_global_forwarding_rule" "google_managed" {
  provider   = google-beta
  name       = "fw-rule-${local.random_suffix}"
  target     = google_compute_target_https_proxy.google_managed[0].id
  ip_address = google_compute_global_address.gca.address
  port_range = "443"
  count      = var.google_managed_tls ? 1 : 0
}
