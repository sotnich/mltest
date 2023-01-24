variable "aws_region" {
    type = string
    default = "eu-west-3"
}

variable "project_name" {
    type        = string
    default     = "s-mltest2"
    description = "The project identifier is used to uniquely namespace resources"
}

data "aws_caller_identity" "current" {}
#variable "aws_account" {
#    type = string
#    default = data.aws_caller_identity.current.account_id
#}
locals {
    account_id = data.aws_caller_identity.current.account_id
}

variable "redshift_database_name" {
    type        = string
    default     = "dev"
    description = "The name of the first database to be created when the cluster is created"
}

variable "redshift_admin_user" {
    type        = string
    default     = "admin"
    description = "(Required unless a snapshot_identifier is provided) Username for the master DB user"
}

variable "redshift_admin_password" {
    type        = string
    default     = "Sotnich#-666"
    description = "(Required unless a snapshot_identifier is provided) Password for the master DB user"
}