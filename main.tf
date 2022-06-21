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
    ports = concat(
      ["30000-32767", "3000", "5000"],
      var.custom_health_check_ports
    )
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

resource "google_compute_url_map" "cn_lb" {
  name            = "lb-${var.name}-${local.random_suffix}"
  default_service = google_compute_backend_bucket.cn_lb.id

  dynamic "host_rule" {
    for_each = var.negs
    content {
      hosts        = lookup(host_rule.value, "hostnames", [])
      path_matcher = host_rule.key
    }
  }
  dynamic "host_rule" {
    for_each = var.services
    content {
      hosts        = lookup(host_rule.value, "hostnames", [])
      path_matcher = host_rule.key
    }
  }
  dynamic "host_rule" {
    for_each = var.buckets
    content {
      hosts        = lookup(host_rule.value, "hostnames", [])
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = var.negs
    content {
      name            = path_matcher.key
      default_service = google_compute_backend_service.app_backend[path_matcher.key].id
      dynamic "path_rule" {
        for_each = var.mask_metrics_endpoint ? [1] : []
        content {
          paths = [
            "/metrics",
          ]
          service = google_compute_backend_bucket.cn_lb.id
        }
      }
    }
  }
  dynamic "path_matcher" {
    for_each = var.services
    content {
      name            = path_matcher.key
      default_service = google_compute_backend_service.cloudrun[path_matcher.key].id
      dynamic "path_rule" {
        for_each = var.mask_metrics_endpoint ? [1] : []
        content {
          paths = [
            "/metrics",
          ]
          service = google_compute_backend_bucket.cn_lb.id
        }
      }
    }
  }
  dynamic "path_matcher" {
    for_each = var.buckets
    content {
      name            = path_matcher.key
      default_service = google_compute_backend_bucket.bucket[path_matcher.key].id
    }
  }
}

