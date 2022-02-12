terraform {
  required_version = "1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.10.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.5.0"
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

