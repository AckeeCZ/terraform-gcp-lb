data "google_cloud_run_service" "cloud_run_service" {
  for_each = var.services
  name     = each.key
  location = lookup(each.value, "location", var.region)
}

resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  for_each              = var.services
  name                  = var.use_random_postfix_for_network_endpoint_group ? "${each.key}-${local.random_suffix}" : each.key
  network_endpoint_type = "SERVERLESS"
  region                = lookup(each.value, "location", var.region)
  cloud_run {
    service = data.google_cloud_run_service.cloud_run_service[each.key].name
  }
}

resource "google_compute_backend_service" "cloudrun" {
  provider = google-beta
  for_each = var.services
  name     = "${each.key}-${local.random_suffix}"

  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg[each.key].id
  }
  dynamic "iap" {
    for_each = [for i in [lookup(var.iap_setup, each.key, var.default_iap_setup)] : i if i != null]
    content {
      oauth2_client_id     = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }
  log_config {
    enable      = true
    sample_rate = var.log_config_sample_rate
  }
}
