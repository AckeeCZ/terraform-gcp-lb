terraform {
  required_version = "1.10.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.50.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.12.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
  }
}

