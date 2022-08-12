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
