resource "google_compute_backend_bucket" "bucket" {
  for_each    = var.buckets
  name        = "${each.key}-${local.random_suffix}"
  bucket_name = each.key
  enable_cdn  = lookup(each.value, "enable_cdn", false)
}
