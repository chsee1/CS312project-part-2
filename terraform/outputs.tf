output "instance_public_ip" {
  description = "Public IP of the Minecraft server"
  value       = aws_instance.minecraft.public_ip
}

output "instance_id" {
  description = "EC2 instance ID (used to wait for instance readiness)"
  value       = aws_instance.minecraft.id
}