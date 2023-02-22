#------------------
# terraform configuration
#------------------
terraform {
  required_version = ">=0.13"
  # 属性によって「=」がいるやつといらないやつがあるから都度公式を確認する
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
  backend "s3" {
    bucket  = "tastylog-tfstate-bucket-kato"
    key     = "tastylog-dev.tfstate"
    region  = "ap-northeast-1"
    profile = "terraform"
  }
}

#--------------------
# provider
#--------------------
provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

#--------------------
# variables
#--------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain" {
  type = string
}