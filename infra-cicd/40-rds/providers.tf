terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
   backend "s3" {
    bucket       = "roboshop-infra-s3"
    key          = "roboshop-infra-dev/rds/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # New S3 native locking!
  }
}

provider "aws" {
  region = "us-east-1"
}