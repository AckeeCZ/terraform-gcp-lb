resource "google_compute_health_check" "cn_lb" {
  for_each = var.negs
  name     = "health-check-${each.key}-${local.random_suffix}"

  timeout_sec         = lookup(each.value, "timeout_sec", var.timeout_sec)
  check_interval_sec  = lookup(each.value, "check_interval_sec", var.check_interval_sec)
  healthy_threshold   = lookup(each.value, "healthy_threshold", var.healthy_threshold)
  unhealthy_threshold = lookup(each.value, "unhealthy_threshold", var.unhealthy_threshold)

  dynamic "http_health_check" {
    for_each = lookup(each.value, "http_backend_protocol", var.http_backend_protocol) == "HTTP" ? [1] : []
    content {
      port_specification = "USE_SERVING_PORT"
      request_path       = lookup(each.value, "health_check_request_path", var.health_check_request_path)
    }
  }
  dynamic "http2_health_check" {
    for_each = lookup(each.value, "http_backend_protocol", var.http_backend_protocol) == "HTTP2" ? [1] : []
    content {
      port_specification = "USE_SERVING_PORT"
      request_path       = lookup(each.value, "health_check_request_path", var.health_check_request_path)
    }
  }
  dynamic "https_health_check" {
    for_each = lookup(each.value, "http_backend_protocol", var.http_backend_protocol) == "HTTPS" ? [1] : []
    content {
      port_specification = "USE_SERVING_PORT"
      request_path       = lookup(each.value, "health_check_request_path", var.health_check_request_path)
    }
  }
}
