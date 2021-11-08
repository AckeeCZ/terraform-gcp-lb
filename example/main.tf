provider "google" {
  project = var.project
  region  = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.zone
}

variable "project" {
}

resource "google_compute_network" "neg_test" {
  name                    = "neg-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "neg_test" {
  name          = "neg-subnetwork"
  ip_cidr_range = "172.16.117.0/24"
  region        = var.region
  network       = google_compute_network.neg_test.id
}

# In production, this is generated by creating k8s Service with "cloud.google.com/neg" annotation
resource "google_compute_network_endpoint_group" "neg" {
  name         = "ackee-api-unicorn"
  network      = google_compute_network.neg_test.id
  subnetwork   = google_compute_subnetwork.neg_test.id
  default_port = "90"
  zone         = var.zone
}

module "api-unicorn" {
  source                 = "../"
  name                   = "api-unicorn"
  project                = var.project
  region                 = var.zone
  neg_name               = "ackee-api-unicorn"
  hostnames              = ["api-unicorn.ackee.cz"]
  google_managed_tls     = true
  log_config_sample_rate = "0.5"
  depends_on = [
    google_compute_network_endpoint_group.neg,
  ]
}

variable "region" {
  default = "europe-west3"
}

variable "zone" {
  default = "europe-west3-c"
}
