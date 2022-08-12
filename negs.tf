data "google_compute_zones" "available" {
  for_each = var.negs
  project  = var.project
  region   = lookup(each.value, "zone", var.region)
}

data "google_compute_network_endpoint_group" "cn_lb" {
  for_each = local.endpoint_zone_groups
  name     = split("␟", each.value)[0]
  zone     = split("␟", each.value)[1]
}

resource "google_compute_backend_service" "app_backend" {
  for_each = var.negs
  provider = google-beta

  name                  = "${each.key}-${local.random_suffix}"
  health_checks         = [google_compute_health_check.cn_lb[each.key].id]
  load_balancing_scheme = "EXTERNAL"
  protocol              = lookup(each.value, "http_backend_protocol", var.http_backend_protocol)
  timeout_sec           = lookup(each.value, "http_backend_timeout", var.http_backend_timeout)

  dynamic "backend" {
    for_each = concat(
      [for i in local.endpoint_zone_groups : data.google_compute_network_endpoint_group.cn_lb[i] if split("␟", i)[0] == each.key],
      lookup(each.value, "additional_negs", [])
    )
    content {
      group          = backend.value.id
      balancing_mode = "RATE"
      max_rate       = 1
    }
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
