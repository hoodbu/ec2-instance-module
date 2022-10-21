resource "tls_private_key" "pros_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "aws_west1_key" {
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

locals {
  ubu_user_data = <<EOF
#!/bin/bash
sudo hostnamectl set-hostname "Ubuntu"
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo echo 'ubuntu:Prosim0123!' | /usr/sbin/chpasswd
sudo apt update -y
sudo apt upgrade -y
sudo apt-get -y install traceroute unzip build-essential git gcc hping3 apache2 net-tools
sudo apt autoremove
sudo /etc/init.d/ssh restart
sudo echo "<html><h1>Prosimo is awesome</h1></html>" > /var/www/html/index.html 
EOF
}

module "my-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.222.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.222.1.0/24"]
  public_subnets  = ["10.222.101.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Name = "2021-09"
  }
  providers = {
    aws = aws.west
  }
}

module "security_group_1" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  name                = "Ubuntu Security Group"
  description         = "Security group for example usage with EC2 instance"
  vpc_id              = module.my-vpc.vpc_id
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
  name                        = "AWS-ubu"
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = var.ec2_key_name
  subnet_id                   = element(module.my-vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group_1.this_security_group_id]
  associate_public_ip_address = true
  user_data_base64            = base64encode(local.ubu_user_data)
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
