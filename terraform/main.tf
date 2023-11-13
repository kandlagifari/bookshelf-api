terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }
  }
 backend "s3" {
   bucket = "kobokan-aer-terraform-remote-state-bucket"
   key    = "my_lambda/terraform.tfstate"
   region = "ap-southeast-3"
 }
}

provider "aws" {
  region = "ap-southeast-3"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "kobokan-aer-terraform-remote-state-bucket"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }
}