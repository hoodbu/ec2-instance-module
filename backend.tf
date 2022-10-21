terraform {
  required_version = ">= 1.0"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "umair-prosimo"
    workspaces {
      name = "ec2-instance-module"
    }
  }
}
