terraform {
  required_version = "1.0.10"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.90.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1.0"
    }
  }
}
