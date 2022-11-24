terraform {
  required_version = ">= 1.0"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "umair-rafay"
    workspaces {
      name = "ec2-instance-module"
    }
  }
}
