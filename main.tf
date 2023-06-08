resource "tls_private_key" "pros_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "aws_west2_key" {
  provider   = aws.west
  key_name   = var.ec2_key_name
  public_key = tls_private_key.pros_key.public_key_openssh
}

##################################################################
# Data source to get AMI details
##################################################################
data "aws_ami" "ubuntu" {
  provider    = aws.west
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

data "template_file" "ubu_user_data" {
  template = file("${path.module}/aws_bootstrap.sh")
  vars = {
    name     = "Frontend"
    password = var.workload_password
  }
}
module "tf-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tf-vpc"
  cidr = "10.222.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.222.1.0/24"]
  public_subnets  = ["10.222.101.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Name = "tf-vpc"
  }
  providers = {
    aws = aws.west
  }
}

module "security_group_1" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "Ubuntu Security Group"
  description         = "Security group for example usage with EC2 instance"
  vpc_id              = module.tf-vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
  providers = {
    aws = aws.west
  }
}

module "aws_ubu_1" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  instance_type               = "t3.micro"
  name                        = "umair-tf-ubu"
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = var.ec2_key_name
  subnet_id                   = element(module.tf-vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group_1.this_security_group_id]
  associate_public_ip_address = true
  user_data_base64            = base64encode(data.template_file.ubu_user_data.rendered)
  providers = {
    aws = aws.west
  }
}

output "Public_IP" {
  value = module.aws_ubu_1.public_ip
}

### Code below needs to output Private IP.

data "aws_network_interface" "aws_ubu_1" {
  provider = aws.west
  id       = module.aws_ubu_1.primary_network_interface_id
}

# private_ip = data.aws_network_interface.aws_ubu_1.private_ip

output "Private_IP" {
  value = data.aws_network_interface.aws_ubu_1.private_ip
}
