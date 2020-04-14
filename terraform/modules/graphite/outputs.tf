# Graphite Public IP Address
output "graphite_public_ip" {
  description = "Graphite public IP addresses"
  value       = aws_instance.graphite.public_ip
}

# Graphite Private IP Address
output "graphite_private_ip" {
  description = "Graphite private IP addresses"
  value       = aws_instance.graphite.private_ip
}

# Graphite Public DNS Name
output "graphite_public_dns" {
  description = "Graphite public DNS Names"
  value       = aws_instance.graphite.public_dns
}
