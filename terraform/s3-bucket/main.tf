terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.43"
      #     version = ">= 5.43.0"
    }
  }
  #  backend "s3" {
  #    bucket         = "tf-state-mp-octopus"
  #    dynamodb_table = "tf-state-mp-octopus"
  #    key            = "buildkite-artifacts/terraform.tfstate"
  #    region         = "ap-southeast-2"
  #    encrypt        = true
  #  }
}

# US East (Northern Virginia)
provider "aws" {

  region = "ap-southeast-2"
  #  default_tags {
  #    tags = local.tags
  #  }
}


module "kbthe-transactions" {
  source        = "./modules/s3"
  bucket_prefix = "kbthe-transactions"
  versioning    = true
  object_expiry = 30 # delete objects after 30 days
}

