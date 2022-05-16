terraform {
  required_version = "1.1.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.20.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.20.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.3.0"
    }
  }
}

