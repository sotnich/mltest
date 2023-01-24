terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }

#        redshift = {
#            source = "brainly/redshift"
#        }
    }
}

provider "aws" {
    region = var.aws_region
    profile = "gdc"
    default_tags {
        tags = {
            Environment = "learning"
            Owner       = "serg"
            Project     = "mlops-review"
        }
    }
}