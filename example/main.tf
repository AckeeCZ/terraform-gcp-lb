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
resource "google_compute_network_endpoint_group" "neg_one" {
  name         = "ackee-api-unicorn-one"
  network      = google_compute_network.neg_test.id
  subnetwork   = google_compute_subnetwork.neg_test.id
  default_port = "90"
  zone         = var.zone
}

resource "google_compute_network_endpoint_group" "neg_two" {
  name         = "ackee-api-unicorn-two"
  network      = google_compute_network.neg_test.id
  subnetwork   = google_compute_subnetwork.neg_test.id
  default_port = "90"
  zone         = var.zone
}

resource "google_cloud_run_service" "default_one" {
  name     = "cloudrun-srv-tst-one"
  location = "europe-west3"

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service" "default_two" {
  name     = "cloudrun-srv-tst-two"
  location = "europe-west3"

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  for_each = {
    "one" : {
      "location" : google_cloud_run_service.default_one.location,
      "project" : google_cloud_run_service.default_one.project,
      "name" : google_cloud_run_service.default_one.name,
    },
    "two" : {
      "location" : google_cloud_run_service.default_two.location,
      "project" : google_cloud_run_service.default_two.project,
      "name" : google_cloud_run_service.default_two.name,
    }
  }
  location    = each.value.location
  project     = each.value.project
  service     = each.value.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

# There are issues with uknown resources before apply, run:
#  terraform apply -target=google_compute_network.neg_test -target=google_compute_network_endpoint_group.neg_one -target=google_compute_network_endpoint_group.neg_two -target=google_compute_subnetwork.neg_test
# to avoid them

module "api_unicorn" {
  source                 = "../"
  name                   = "api-unicorn"
  project                = var.project
  region                 = var.region
  google_managed_tls     = true
  log_config_sample_rate = "0.5"
  services = [
    {
      type     = "cloudrun"
      name     = "cloudrun-srv-tst-one"
      location = var.region
    },
    {
      type     = "cloudrun"
      name     = "cloudrun-srv-tst-two"
      location = var.region
    },
    {
      type = "neg"
      name = "ackee-api-unicorn-one"
      zone = var.zone
    },
    {
      type = "neg"
      name = "ackee-api-unicorn-two"
      zone = var.zone
    }
  ]
  url_map = {
    matcher1 = {
      hostnames = ["cloud-run-test-1.ack.ee"]
      path_rules = [
        {
          paths   = ["/api/v1/*"]
          service = "ackee-api-unicorn-one"
        },
        {
          paths   = ["/api/v2/*"]
          service = "cloudrun-srv-tst-two"

        }
      ]
      default_service = "cloudrun-srv-tst-two"
    }
    matcher2 = {
      hostnames = ["api-unicorn-1.ackee.cz"]
      path_rules = [
        {
          paths   = ["/*"]
          service = "ackee-api-unicorn-one"
        },
      ]
      default_service = "ackee-api-unicorn-two"
    }
    matcher3 = {
      hostnames = ["api-unicorn-2.ackee.cz"]
      path_rules = [
        {
          paths   = ["/*"]
          service = "ackee-api-unicorn-two"
        },
      ]
      default_service = "ackee-api-unicorn-two"
    }
    matcher4 = {
      hostnames = ["api-unicorn-4.ackee.cz"]
      route_rules = [
        {
          paths = [
            {
              name                    = "/api/v1/ackee",
              priority                = 1,
              query_parameter_matches = "key",
              url_rewrite             = "/api/v2/ackee"
            }
          ]
          service = "ackee-api-unicorn-one"
        }
      ]
    }
  }
  depends_on = [
    google_compute_network_endpoint_group.neg_one,
    google_compute_network_endpoint_group.neg_two,
  ]
}

variable "region" {
  default = "europe-west3"
}

variable "zone" {
  default = "europe-west3-c"
}

data "google_compute_zones" "available" {
  project = var.project
  region  = var.region
}

output "zones" {
  value = data.google_compute_zones.available.names
}

data "google_compute_zones" "available_zone" {
  project = var.project
  region  = var.zone
}

output "zone_zones" {
  value = data.google_compute_zones.available_zone.names
}
