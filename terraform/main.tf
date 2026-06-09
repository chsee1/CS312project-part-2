# terraform/main.tf
provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-server-sg"
  description = "Allow Minecraft and SSH traffic"

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In production, restrict this to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "minecraft_server" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 (Verify for your region)
  instance_type = "t3.medium"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]

  tags = {
    Name = "Acme-Minecraft-Server"
  }
}
