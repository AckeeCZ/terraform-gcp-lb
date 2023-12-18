locals {
  random_suffix            = random_string.random_suffix.result
  managed_certificate_name = var.managed_certificate_name != null ? var.managed_certificate_name : "${var.name}-cert-managed"
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
    for_each = var.url_map
    content {
      hosts        = host_rule.value.hostnames
      path_matcher = host_rule.key
    }
  }
  dynamic "path_matcher" {
    for_each = var.url_map
    content {
      name = path_matcher.key
      default_service = lookup(
        local.negs, path_matcher.value.default_service,
        lookup(local.services, path_matcher.value.default_service,
          lookup(local.buckets, path_matcher.value.default_service, null)
        )
        ).type == "neg" ? google_compute_backend_service.app_backend[path_matcher.value.default_service].id : lookup(
        local.negs, path_matcher.value.default_service,
        lookup(local.services, path_matcher.value.default_service,
          lookup(local.buckets, path_matcher.value.default_service, null)
        )
        ).type == "cloudrun" ? google_compute_backend_service.cloudrun[path_matcher.value.default_service].id : lookup(
        local.negs, path_matcher.value.default_service,
        lookup(local.services, path_matcher.value.default_service,
          lookup(local.buckets, path_matcher.value.default_service, null)
        )
        ).type == "bucket" ? google_compute_backend_bucket.bucket[path_matcher.value.default_service].id : lookup(
        local.negs, path_matcher.value.default_service,
        lookup(local.services, path_matcher.value.default_service,
          lookup(local.buckets, path_matcher.value.default_service,
            lookup(local.backends, path_matcher.value.default_service, null)
          )
        )
      ).type == "backend" ? google_compute_backend_service.backend[path_matcher.value.default_service].id : null

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules
        content {
          paths = path_rule.value.paths
          service = lookup(
            local.negs, path_rule.value.service,
            lookup(local.services, path_rule.value.service,
              lookup(local.buckets, path_rule.value.service,
                lookup(local.backends, path_rule.value.service, null)
              )
            )
            ).type == "neg" ? google_compute_backend_service.app_backend[path_rule.value.service].id : lookup(
            local.negs, path_rule.value.service,
            lookup(local.services, path_rule.value.service,
              lookup(local.buckets, path_rule.value.service,
                lookup(local.backends, path_rule.value.service, null)
              )
            )
            ).type == "cloudrun" ? google_compute_backend_service.cloudrun[path_rule.value.service].id : lookup(
            local.negs, path_rule.value.service,
            lookup(local.services, path_rule.value.service,
              lookup(local.buckets, path_rule.value.service,
                lookup(local.backends, path_rule.value.service, null)
              )
            )
            ).type == "bucket" ? google_compute_backend_bucket.bucket[path_rule.value.service].id : lookup(
            local.negs, path_rule.value.service,
            lookup(local.services, path_rule.value.service,
              lookup(local.buckets, path_rule.value.service,
                lookup(local.backends, path_rule.value.service, null)
              )
            )
          ).type == "backend" ? google_compute_backend_service.backend[path_rule.value.service].id : null
        }
      }
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
}

