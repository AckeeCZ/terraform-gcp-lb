provider "random" {
  version = "~> 3.1.0"
}

provider "google" {
  version = "~> 3.75.0"
  project = var.project
  region  = var.zone
}

provider "google-beta" {
  version = "~> 3.76.0"
  project = var.project
  region  = var.zone
}

provider "tls" {
  version = "~> 3.1.0"
}

variable "project" {
}

module "api-unicorn" {
  source             = "../"
  name               = "api-unicorn"
  project            = "FILL-IT-YOURSELF"
  region             = var.region
  neg_name           = "ackee-api-unicorn"
  hostnames          = ["api-unicorn.ackee.cz"]
  google_managed_tls = true
}

variable "region" {
  default = "europe-west3"
}

variable "zone" {
  default = "europe-west3-c"
}
