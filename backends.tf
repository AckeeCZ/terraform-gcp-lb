locals {
  backends = {
    for k, v in var.backends : k => merge({
      type = "backend",
      },
      v
    )
  }
}

resource "google_compute_health_check" "backends" {
  for_each = anytrue(flatten([
    for k, v in local.backends :
    [for i in v.backends : true if lookup(local.negs, i.service, null) != null]
  ])) ? local.backends : {}

  name = "health-check-${each.key}-${local.random_suffix}"

  timeout_sec         = each.value.timeout_sec == null ? var.timeout_sec : each.value.timeout_sec
  check_interval_sec  = each.value.check_interval_sec == null ? var.check_interval_sec : each.value.check_interval_sec
  healthy_threshold   = each.value.healthy_threshold == null ? var.healthy_threshold : each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold == null ? var.unhealthy_threshold : each.value.unhealthy_threshold

  dynamic "http_health_check" {
    for_each = each.value.http_backend_protocol == null ? [1] : []
    content {
      port_specification = "USE_SERVING_PORT"
      request_path       = each.value.health_check_request_path == null ? var.health_check_request_path : each.value.health_check_request_path
    }
  }
  dynamic "http2_health_check" {
    for_each = each.value.http_backend_protocol == "HTTP2" ? [1] : []
    content {
      port_specification = "USE_SERVING_PORT"
      request_path       = each.value.health_check_request_path == null ? var.health_check_request_path : each.value.health_check_request_path
    }
  }
  dynamic "https_health_check" {
    for_each = each.value.http_backend_protocol == "HTTPS" ? [1] : []
    content {
      port_specification = "USE_SERVING_PORT"
      request_path       = each.value.health_check_request_path == null ? var.health_check_request_path : each.value.health_check_request_path
    }
  }
}

resource "google_compute_backend_service" "backend" {
  for_each = local.backends
  provider = google-beta

  name                  = "${each.key}-${local.random_suffix}"
  load_balancing_scheme = "EXTERNAL"
  protocol              = var.http_backend_protocol
  timeout_sec           = var.http_backend_timeout
  health_checks         = lookup(local.negs, each.key, null) != null ? google_compute_health_check.backends[*].id : null

  dynamic "backend" {
    for_each = [for i in flatten([
      for j in each.value.backends : concat([
        for i in local.endpoint_zone_groups : merge(
          data.google_compute_network_endpoint_group.cn_lb[i],
          {
            max_rate = j.max_rate
          }
        ) if split("␟", i)[0] == j.service
        ], [
        try(
          merge(
            google_compute_region_network_endpoint_group.cloudrun_neg[j.service],
            {
              max_rate = j.max_rate
            }
          )
        , null)
        ],
      )
    ]) : i if i != null]
    content {
      group          = backend.value.id
      balancing_mode = "RATE"
      max_rate       = backend.value.max_rate
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
