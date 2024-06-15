terraform {
  required_version = "1.6.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.85.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.30.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
  }
}

