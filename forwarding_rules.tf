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

// external signed certificate variant

resource "google_compute_target_https_proxy" "external_signed" {
  name    = "http-proxy-${local.random_suffix}"
  url_map = google_compute_url_map.cn_lb.id

  ssl_certificates = [google_compute_ssl_certificate.external_certs[0].self_link]
  count            = var.certificate != null ? 1 : 0
}

resource "google_compute_global_forwarding_rule" "external_signed" {
  provider   = google-beta
  name       = "fw-rule-${local.random_suffix}"
  target     = google_compute_target_https_proxy.external_signed[0].id
  ip_address = google_compute_global_address.gca.address
  port_range = "443"
  count      = var.certificate != null ? 1 : 0
}

// Non-TLS load balancer

resource "google_compute_target_http_proxy" "non_tls" {
  name    = "non-tls-proxy-${local.random_suffix}"
  url_map = google_compute_url_map.cn_lb.id
  count   = var.allow_non_tls_frontend ? 1 : 0
}

resource "google_compute_global_forwarding_rule" "non_tls" {
  name       = "non-tls-fw-rule-${local.random_suffix}"
  target     = google_compute_target_http_proxy.non_tls[0].id
  ip_address = google_compute_global_address.gca.address
  port_range = "80"
  count      = var.allow_non_tls_frontend ? 1 : 0
}

