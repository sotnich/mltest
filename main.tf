terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider "aws" {
    region = "eu-west-3"
}

resource "aws_s3_bucket" "landing_bucket" {
    bucket = "sotnich-learn-mltest"
    force_destroy = true
}