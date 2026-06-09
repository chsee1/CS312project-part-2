# Acme Corp Minecraft Infrastructure-as-Code

## Background
Welcome to the automated deployment pipeline for the Acme Corp Minecraft server. To move away from the manual, error-prone processes of the past, we use **Terraform** to provision AWS cloud resources and **Ansible** to configure the server environment.

This setup ensures:
1.  **Persistence**: The server starts automatically on system boot.
2.  **Graceful Shutdown**: Prevents world data corruption by allowing the Java process to save state before termination.
3.  **Reproducibility**: The entire stack can be destroyed and recreated in minutes.

## Requirements
To run this pipeline, you need the following:

### Tools
*   [Terraform](https://www.terraform.io/downloads) (v1.0+)
*   [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
*   [AWS CLI](https://aws.amazon.com/cli/) configured with valid credentials.
*   `nmap` for connectivity verification.

### Credentials & Environment
*   **AWS Credentials**: Ensure your environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) are set or use `aws configure`.
*   **SSH Key**: An existing AWS Key Pair is required to allow Ansible to configure the instance.

## Architecture Pipeline
```mermaid
graph LR
    A[Local Machine] -->|terraform apply| B(AWS EC2 + Networking)
    B -->|ansible-playbook| C(Minecraft Configuration)
    C -->|systemd| D[Minecraft Server Running]
