terraform {
  required_version = ">= 1.0.6"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "uhoodbhoy-aviatrix"
    workspaces {
      name = "ec2-instance-module"
    }
  }
}
