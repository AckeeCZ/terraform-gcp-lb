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

  dns_names = var.dont_use_dns_names_in_certificate == true ? [] : concat(
    flatten([
      for i in var.negs :
      compact(lookup(i, "hostnames", []))
    ]),
    flatten([
      for i in var.services :
      compact(lookup(i, "hostnames", []))
    ]),
  )

  lifecycle {
    ignore_changes = [
      subject
    ]
  }
}

resource "random_id" "external_certificate" {
  byte_length = 4
  prefix      = "${var.name}-cert-external-signed"

  # For security, do not expose raw certificate values in the output
  keepers = {
    private_key = sha256(var.private_key)
    certificate = sha256(var.certificate)
  }
  count = var.certificate != null ? 1 : 0
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

resource "google_compute_ssl_certificate" "external_certs" {
  name        = random_id.external_certificate[0].hex
  private_key = var.private_key
  certificate = var.certificate

  lifecycle {
    create_before_destroy = true
  }
  count = var.certificate != null ? 1 : 0
}

resource "google_compute_managed_ssl_certificate" "gcs_certs" {
  name = local.managed_certificate_name

  managed {
    domains = concat(
      flatten([
        for i in var.negs :
        compact(lookup(i, "hostnames", []))
      ]),
      flatten([
        for i in var.services :
        compact(lookup(i, "hostnames", []))
      ]),
    )
  }
  count = var.google_managed_tls ? 1 : 0
}
