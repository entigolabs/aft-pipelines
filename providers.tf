terraform {
  required_version = ">= 1.2" 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9"
    }
    archive = {
      source = "hashicorp/archive"
      version = ">= 2.0"
    }
    external = {
      source = "hashicorp/external"
      version = ">= 2.0"
    }
  }
}


