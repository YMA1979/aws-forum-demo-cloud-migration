#
# Read setup specific variables from external yaml file
#
locals {
  setup = yamldecode(file(var.setupfile))
}

#
# Provider section
#
provider "aws" {
  region = local.setup.aws.region
}

provider "local" {
  version = "~> 1.4"
}

provider "random" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
}

#
# Create Secret Store and Store BIG-IP Password
#
resource "aws_secretsmanager_secret" "bigip" {
  name = format("%s-bigip-secret-%s", local.setup.owner, random_id.id.hex)

  tags = {
    Name        = format("%s-bigip-secret-%s", local.setup.owner, random_id.id.hex)
    Terraform   = "true"
    Environment = local.setup.aws.environment
    Owner       = local.setup.owner
  }
}
resource "aws_secretsmanager_secret_version" "bigip-pwd" {
  secret_id     = aws_secretsmanager_secret.bigip.id
  secret_string = local.setup.bigip.admin_password
}

#
# Create the VPC 
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc-%s", local.setup.owner, random_id.id.hex)
  cidr                 = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = local.setup.aws.azs

  public_subnets = [
    for num in range(length(local.setup.aws.azs)) :
    cidrsubnet("10.0.0.0/16", 8, num)
  ]

  vpc_tags = {
    Name        = format("%s-vpc-%s", local.setup.owner, random_id.id.hex)
    Terraform   = "true"
    Environment = local.setup.aws.environment
    Owner       = local.setup.owner
  }

  public_subnet_tags = {
    Name        = format("%s-pub-subnet-%s", local.setup.owner, random_id.id.hex)
    Terraform   = "true"
    Environment = local.setup.aws.environment
    Owner       = local.setup.owner
  }

  public_route_table_tags = {
    Name        = format("%s-pub-rt-%s", local.setup.owner, random_id.id.hex)
    Terraform   = "true"
    Environment = local.setup.aws.environment
    Owner       = local.setup.owner
  }

  igw_tags = {
    Name        = format("%s-igw-%s", local.setup.owner, random_id.id.hex)
    Terraform   = "true"
    Environment = local.setup.aws.environment
    Owner       = local.setup.owner
  }
}

#
# Create necessary security groups
#
module security {
  source = "./modules/security"

  owner       = local.setup.owner
  environment = local.setup.aws.environment
  random_id   = random_id.id.hex
  vpc_id      = module.vpc.vpc_id
}

#
# Create BIG-IP
#
module bigip {
  source = "./modules/bigip"

  owner       = local.setup.owner
  environment = local.setup.aws.environment
  random_id   = random_id.id.hex

  f5_instance_count           = length(local.setup.aws.azs)
  ec2_key_name                = local.setup.aws.ec2_key_name
  aws_secretmanager_secret_id = aws_secretsmanager_secret.bigip.id

  mgmt_subnet_security_group_ids = [
    module.security.web_server_sg,
    module.security.web_server_secure_sg,
    module.security.ssh_secure_sg,
    module.security.bigip_mgmt_secure_sg
  ]

  vpc_mgmt_subnet_ids = module.vpc.public_subnets
  f5_ami_search_name  = "F5 Networks BIGIP-14.0.1*BYOL*All Modules 1 Boot*"
}

#
# Create Autodiscovery WebServers
#
module webserver {
  source = "./modules/webserver"

  owner        = local.setup.owner
  environment  = local.setup.aws.environment
  random_id    = random_id.id.hex
  subnet_id    = element(module.vpc.public_subnets, 0)
  ec2_key_name = local.setup.aws.ec2_key_name
  color        = ["ff5e13", "0072bb"]
  color_tag    = ["orange", "blue"]
  server_count = 2

  sec_group_ids = [
    module.security.web_server_sg,
    module.security.web_server_secure_sg
  ]

  tenant              = local.setup.atc.tenant
  application         = local.setup.atc.application
  server_display_name = local.setup.webserver.displayname
  autodiscovery       = "true"
}

#
# Create Graphite Instance
#
module graphite_grafana {
  source = "./modules/graphite_grafana"

  owner        = local.setup.owner
  environment  = local.setup.aws.environment
  random_id    = random_id.id.hex
  subnet_id    = element(module.vpc.public_subnets, 0)
  ec2_key_name = local.setup.aws.ec2_key_name

  sec_group_ids = [
    module.security.web_server_sg,
    module.security.grafana_sg,
    module.security.graphite_statsd_sg
  ]
}

#
# Create ELK Instance
#
module elk {
  source = "./modules/elk"

  owner        = local.setup.owner
  environment  = local.setup.aws.environment
  random_id    = random_id.id.hex
  subnet_id    = element(module.vpc.public_subnets, 0)
  ec2_key_name = local.setup.aws.ec2_key_name

  sec_group_ids = [
    module.security.web_server_sg,
    module.security.ssh_secure_sg,
    module.security.elasticsearch_sg,
    module.security.kibana_sg
  ]
}

data "template_file" "ansible_dynamic_inventory_config" {
  template = file("${path.module}/aws_ec2.yml.tpl")
  vars = {
    region      = local.setup.aws.region
    environment = local.setup.aws.environment
  }
}

resource "local_file" "ansible_dynamic_inventory_config" {
  content  = data.template_file.ansible_dynamic_inventory_config.rendered
  filename = var.awsinventoryconfig
}

data "template_file" "generate_load_script" {
  template = file("${path.module}/generate_load.sh.tpl")
  vars = {
    bigip_address = element(module.bigip.mgmt_public_dns, 0)
  }
}

resource "local_file" "generate_load_script" {
  content  = data.template_file.generate_load_script.rendered
  filename = var.generateloadscript
}
