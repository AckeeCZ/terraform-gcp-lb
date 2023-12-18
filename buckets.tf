locals {
  buckets = {
    for item in var.services : item.name => item if item.type == "bucket"
  }
}
resource "google_compute_backend_bucket" "bucket" {
  for_each    = local.buckets
  name        = "${each.key}-${local.random_suffix}"
  bucket_name = each.key
  enable_cdn  = lookup(each.value, "enable_cdn", false)
}
