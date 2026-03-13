output "public_ip" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.lab00.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${path.module}/${var.key_name}.pem ec2-user@${aws_instance.lab00.public_ip}"
}

output "pem_file" {
  description = "Path to generated private key"
  value       = local_file.private_key_pem.filename
}
