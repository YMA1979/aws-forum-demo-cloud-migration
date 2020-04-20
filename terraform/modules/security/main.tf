
#
# Create a security group for port 80 traffic
#
module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = format("%s-webserver-sg-%s", var.owner, var.random_id)
  description = "Security group for web-server with HTTP ports"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for port 443 traffic
#
module "web_server_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/https-443"

  name        = format("%s-webserver-secure-sg-%s", var.owner, var.random_id)
  description = "Security group for web-server with HTTPS ports"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for port 8443 traffic
#
module "bigip_mgmt_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/https-8443"

  name        = format("%s-bigip-mgmt-sg-%s", var.owner, var.random_id)
  description = "Security group for BIG-IP MGMT Interface"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for SSH traffic
#
module "ssh_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name        = format("%s-ssh-sg-%s", var.owner, var.random_id)
  description = "Security group for SSH ports open within VPC"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for Grafana dashboard
#
module "grafana_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/grafana"

  name        = format("%s-grafana-sg-%s", var.owner, var.random_id)
  description = "Security group for Grafana Dashboard"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for Graphite/StatsD dashboard
#
module "graphite_statsd_sg" {
  source = "github.com/boeboe/terraform-aws-security-group//modules/graphite-statsd?ref=v3.7.0.2"

  name        = format("%s-graphite-statsd-sg-%s", var.owner, var.random_id)
  description = "Security group for Graphite and StatsD"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for Elastisearch
#
module "elasticsearch_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/elasticsearch"

  name        = format("%s-elasticsearch-sg-%s", var.owner, var.random_id)
  description = "Security group for Elasticsearch"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for Kibana dashboard
#
module "kibana_sg" {
  source = "github.com/boeboe/terraform-aws-security-group//modules/kibana?ref=v3.7.0.2"

  name        = format("%s-kibana-sg-%s", var.owner, var.random_id)
  description = "Security group for Kibana"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}
