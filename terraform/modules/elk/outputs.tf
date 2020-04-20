# ELK Public IP Address
output "elk_public_ip" {
  description = "ELK public IP addresses"
  value       = aws_instance.elk.public_ip
}

# ELK Private IP Address
output "elk_private_ip" {
  description = "ELK private IP addresses"
  value       = aws_instance.elk.private_ip
}

# ELK Public DNS Name
output "elk_public_dns" {
  description = "ELK public DNS Names"
  value       = aws_instance.elk.public_dns
}
