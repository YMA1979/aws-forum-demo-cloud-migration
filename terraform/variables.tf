variable "setupfile" {
  description = "The setup file in yaml format"
  type        = string
  default     = "setup.yml"
}

variable "awsinventoryconfig" {
  description = "The configuration file for AWS dynamic inventory in Ansible"
  type        = string
  default     = "aws_ec2.yml"
}
