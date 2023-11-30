locals {
  random_suffix            = random_string.random_suffix.result
  managed_certificate_name = var.managed_certificate_name != null ? var.managed_certificate_name : "${var.name}-cert-managed"
  endpoint_zone_groups = toset([for i in flatten([
    for k, v in var.negs :
    concat([
      for i in data.google_compute_zones.available :
      [for j in i.names :
      "${k}␟${j}"]
    ], ["${k}␟${lookup(v, "zone", "")}"])
    ]) :
    i if split("␟", i)[1] != ""
  ])
}

resource "random_string" "random_suffix" {
  length  = var.random_suffix_size
  special = false
  upper   = false
}

resource "google_compute_backend_bucket" "cn_lb" {
  name        = "${var.project}-l7-default-backend-${local.random_suffix}"
  bucket_name = google_storage_bucket.cn_lb.name
  enable_cdn  = true
}

resource "google_storage_bucket" "cn_lb" {
  name     = "${var.project}-l7-default-backend-${local.random_suffix}"
  location = var.backend_bucket_location
}

resource "google_compute_url_map" "cn_lb" {
  name            = var.custom_url_map_name == "" ? "lb-${var.name}-${local.random_suffix}" : var.custom_url_map_name
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
      dynamic "path_rule" {
        for_each = length(lookup(path_matcher.value, "paths", [])) > 0 ? [1] : []
        content {
          paths   = lookup(path_matcher.value, "paths", [])
          service = google_compute_backend_service.app_backend[path_matcher.key].id
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
      dynamic "path_rule" {
        for_each = length(lookup(path_matcher.value, "paths", [])) > 0 ? [1] : []
        content {
          paths   = lookup(path_matcher.value, "paths", [])
          service = google_compute_backend_service.cloudrun[path_matcher.key].id
        }
      }
    }
  }
  dynamic "path_matcher" {
    for_each = var.buckets
    content {
      name            = path_matcher.key
      default_service = google_compute_backend_bucket.bucket[path_matcher.key].id
      dynamic "path_rule" {
        for_each = length(lookup(path_matcher.value, "paths", [])) > 0 ? [1] : []
        content {
          paths   = lookup(path_matcher.value, "paths", [])
          service = google_compute_backend_service.bucket[path_matcher.key].id
        }
      }
    }
  }
}

