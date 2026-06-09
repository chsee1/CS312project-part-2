output "instance_public_ip" {
  description = "The public IP address of the Minecraft server"
  value       = aws_instance.minecraft_server.public_ip
}

output "instance_id" {
  description = "EC2 instance ID (used to wait for instance readiness)"
  value       = aws_instance.minecraft_server.id
}