resource "random_string" "random_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "google_compute_global_address" "gca" {
  name    = var.name
  project = var.project
}

resource "tls_private_key" "web_lb_key" {
  algorithm = var.keys_alg
  count     = var.self_signed_tls ? 1 : 0
}

resource "tls_self_signed_cert" "web_lb_cert" {
  key_algorithm         = var.keys_alg
  private_key_pem       = tls_private_key.web_lb_key[0].private_key_pem
  validity_period_hours = var.keys_valid_period

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  subject {
    common_name         = google_compute_global_address.gca.address
    organization        = "n/a"
    organizational_unit = "n/a"
    street_address      = ["n/a"]
    locality            = "n/a"
    province            = "CA"
    country             = "US"
    postal_code         = "12345"
  }
  count = var.self_signed_tls ? 1 : 0
}

resource "google_compute_ssl_certificate" "gcs_certs" {
  name        = "${var.name}-cert-self-signed"
  private_key = tls_private_key.web_lb_key[0].private_key_pem
  certificate = tls_self_signed_cert.web_lb_cert[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }
  count = var.self_signed_tls ? 1 : 0
}

resource "google_compute_managed_ssl_certificate" "gcs_certs" {
  name = "${var.name}-cert-managed"

  managed {
    domains = [var.hostname]
  }
  count = var.google_managed_tls ? 1 : 0
}
