resource "google_compute_health_check" "cn_lb" {
  for_each = local.negs
  name     = "health-check-${each.key}-${local.random_suffix}"

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
