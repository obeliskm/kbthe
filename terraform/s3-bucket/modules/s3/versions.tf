terraform {
  required_providers {
    aws = {
      version = ">= 5"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.6"
}
