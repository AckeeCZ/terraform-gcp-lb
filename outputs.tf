output "ip_address" {
  value       = google_compute_global_address.gca.address
  description = "IP address"
}
