resource "google_storage_bucket" "log_archive_sink" {
  name          = "named-neg-lb-${var.name}-${local.random_suffix}-logs"
  location      = var.backend_bucket_location
  storage_class = "COLDLINE"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = var.logging_sink_bucket_retency
    }
    action {
      type = "Delete"
    }
  }

  count = var.create_logging_sink_bucket ? 1 : 0
}

resource "google_logging_project_sink" "log_archive_sink" {
  name = "named-neg-lb-${var.name}-${local.random_suffix}-logs"

  destination = "storage.googleapis.com/${google_storage_bucket.log_archive_sink[0].name}"
  filter      = "resource.type=http_load_balancer AND resource.labels.url_map_name=\"${google_compute_url_map.cn_lb.name}\""

  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true

  count = var.create_logging_sink_bucket ? 1 : 0
}

# Because our sink uses a unique_writer, we must grant that writer access to the bucket.
resource "google_storage_bucket_iam_binding" "log_archive_sink_writer" {
  bucket = google_storage_bucket.log_archive_sink[0].name
  role   = "roles/storage.objectCreator"
  members = [
    google_logging_project_sink.log_archive_sink[0].writer_identity,
  ]

  count = var.create_logging_sink_bucket ? 1 : 0
}
