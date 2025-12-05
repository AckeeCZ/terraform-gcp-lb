locals {
  random_suffix            = random_string.random_suffix.result
  managed_certificate_name = var.managed_certificate_name != null ? var.managed_certificate_name : "${var.name}-cert-managed"
  negs = {
    for item in var.services : coalesce(item.backend_name, item.name) => item if item.type == "neg"
  }
  endpoint_zone_groups = toset([for i in flatten([
    for k, v in local.negs :
    concat([
      for i in data.google_compute_zones.available :
      [for j in i.names :
      "${k}␟${j}"]
    ], ["${k}␟${lookup(v, "zone", "")}"])
    ]) :
    i if split("␟", i)[1] != ""
  ])
  services = {
    for item in var.services : coalesce(item.backend_name, item.name) => item if item.type == "cloudrun"
  }
  buckets = {
    for item in var.services : item.name => item if item.type == "bucket"
  }
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
      ).type == "bucket" ? google_compute_backend_bucket.bucket[path_matcher.value.default_service].id : null
      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules != null ? path_matcher.value.path_rules : []
        content {
          paths = path_rule.value.paths
          service = lookup(
            local.negs, path_rule.value.service,
            lookup(local.services, path_rule.value.service,
              lookup(local.buckets, path_rule.value.service, null)
            )
            ).type == "neg" ? google_compute_backend_service.app_backend[path_rule.value.service].id : lookup(
            local.negs, path_rule.value.service,
            lookup(local.services, path_rule.value.service,
              lookup(local.buckets, path_rule.value.service, null)
            )
            ).type == "cloudrun" ? google_compute_backend_service.cloudrun[path_rule.value.service].id : lookup(
            local.negs, path_rule.value.service,
            lookup(local.services, path_rule.value.service,
              lookup(local.buckets, path_rule.value.service, null)
            )
          ).type == "bucket" ? google_compute_backend_bucket.bucket[path_rule.value.service].id : null
        }
      }

      dynamic "route_rules" {
        for_each = path_matcher.value.route_rules != null ? { for e in tolist(flatten([
          for route_rule_idx, route_rule in path_matcher.value.route_rules : [
            for path_idx, path in route_rule.paths : {
              path                    = path.name
              path_prefix             = path.name_prefix
              priority                = path.priority
              service                 = route_rule.service
              query_parameter_matches = path.query_parameter_matches
              url_rewrite             = path.url_rewrite
            }
          ]
          ])) : format("%05d", tonumber(e.priority)) => e
        } : {}
        content {
          priority = route_rules.value.priority
          service = lookup(
            local.negs, route_rules.value.service,
            lookup(local.services, route_rules.value.service,
              lookup(local.buckets, route_rules.value.service, null)
            )
            ).type == "neg" ? google_compute_backend_service.app_backend[route_rules.value.service].id : lookup(
            local.negs, route_rules.value.service,
            lookup(local.services, route_rules.value.service,
              lookup(local.buckets, route_rules.value.service, null)
            )
            ).type == "cloudrun" ? google_compute_backend_service.cloudrun[route_rules.value.service].id : lookup(
            local.negs, route_rules.value.service,
            lookup(local.services, route_rules.value.service,
              lookup(local.buckets, route_rules.value.service, null)
            )
          ).type == "bucket" ? google_compute_backend_bucket.bucket[route_rules.value.service].id : null
          match_rules {
            full_path_match = route_rules.value.path != null ? route_rules.value.path : null
            prefix_match    = route_rules.value.path_prefix != null ? route_rules.value.path_prefix : null
            dynamic "query_parameter_matches" {
              for_each = route_rules.value.query_parameter_matches != null ? [1] : []
              content {
                name          = route_rules.value.query_parameter_matches
                present_match = true
              }
            }
          }
          dynamic "route_action" {
            for_each = route_rules.value.url_rewrite != null ? [1] : []
            content {
              url_rewrite {
                path_prefix_rewrite = route_rules.value.url_rewrite
              }
            }
          }
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

