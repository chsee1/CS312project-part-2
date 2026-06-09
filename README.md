https://github.com/chsee1/CS312project-part-2

# Minecraft Server on AWS — Infrastructure as Code

## Background

This project automates the provisioning and configuration of a Minecraft 1.21.1 server on AWS using **Terraform** (infrastructure) and **Ansible** (server configuration). Rather than manually clicking through the AWS Console, every resource is defined in code, versioned in Git, and reproducible in a single pipeline.

The pipeline does the following:

1. **Terraform** provisions an EC2 instance with the correct security group rules (SSH on port 22, Minecraft on port 25565) and outputs the instance's public IP.
2. **Ansible** connects to that instance and configures it: installs Java 21, creates a dedicated `minecraft` user, downloads the server JAR, accepts the EULA, and installs a `systemd` service so the server starts on boot and shuts down cleanly on reboot.

---

## Requirements

### Tools

| Tool | Version | Install |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.5 | `brew install terraform` or see link |
| [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) | >= 2.14 | `pip install ansible` |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | >= 2.0 | See link |
| [nmap](https://nmap.org/download) | any | `brew install nmap` or `apt install nmap` |

### AWS Credentials

Retrieve your credentials from the **AWS Learner Lab** module:

1. Open the Learner Lab and click **AWS Details**
2. Copy the credentials block (`aws_access_key_id`, `aws_secret_access_key`, `aws_session_token`)
3. Paste them into `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = YOUR_KEY
aws_secret_access_key = YOUR_SECRET
aws_session_token = YOUR_TOKEN
```

Or export them as environment variables:

```bash
export AWS_ACCESS_KEY_ID=YOUR_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET
export AWS_SESSION_TOKEN=YOUR_TOKEN
```

### SSH Key

This project expects a key pair named `vockey` to already exist in your AWS account (provided by Learner Lab). The private key should be saved at:

```
ansible/keys/vockey.pem
```

Set correct permissions on the key:

```bash
chmod 400 ansible/keys/vockey.pem
```

---

## Repository Structure

```
.
├── terraform/
│   ├── main.tf          # EC2 instance + security group
│   ├── variables.tf     # Input variables
│   └── outputs.tf       # Public IP output
├── ansible/
│   ├── playbook.yml     # Server configuration playbook
│   ├── keys/
│   │   └── vockey.pem   # SSH private key (not committed to Git)
│   └── templates/
│       └── minecraft.service.j2  # systemd service template
└── README.md
```

---

## Pipeline Diagram

```
┌─────────────────────────────────────────────────────────┐
│                        Local Machine                     │
│                                                          │
│  1. terraform init / apply                               │
│       │                                                  │
│       ▼                                                  │
│  ┌─────────────┐     Creates:                           │
│  │   AWS EC2   │  ← Security Group (ports 22, 25565)    │
│  │  Instance   │  ← Amazon Linux 2, t2.small            │
│  └──────┬──────┘                                        │
│         │ outputs public IP                              │
│         ▼                                                │
│  2. ansible-playbook                                     │
│       │                                                  │
│       ▼                                                  │
│  ┌─────────────────────────────────────────┐            │
│  │           EC2 Instance                  │            │
│  │  - Install Java 21 (Amazon Corretto)    │            │
│  │  - Create minecraft user                │            │
│  │  - Download server.jar (MC 1.21.1)      │            │
│  │  - Accept EULA                          │            │
│  │  - Install & enable systemd service     │            │
│  └─────────────────────────────────────────┘            │
│         │                                                │
│         ▼                                                │
│  3. nmap verify: port 25565 open                        │
└─────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Commands

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd <repo-name>
```

### 2. Provision infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply
```

Review the plan and type `yes` when prompted. When complete, note the public IP printed in the output:

```
Outputs:
instance_public_ip = "54.242.45.191"
```

### 3. Configure the server with Ansible

Use the IP from the Terraform output:

```bash
cd ../ansible
ansible-playbook -i <instance_public_ip>, playbook.yml --private-key=./keys/vockey.pem -u ec2-user
```

> **Note:** The trailing comma after the IP is required — it tells Ansible to treat the value as an inline inventory rather than a file path.

Ansible will run through the following tasks:

- Install Java 21 via `amazon-linux-extras`
- Create a `minecraft` system user
- Download the Minecraft 1.21.1 server JAR
- Write `eula=true` to `eula.txt`
- Deploy the `systemd` service and start it

### 4. Verify the server is reachable

```bash
nmap -sV -Pn -p T:25565 <instance_public_ip>
```

Expected output:

```
PORT      STATE SERVICE   VERSION
25565/tcp open  minecraft Minecraft 1.21.1 (Protocol: 127, Message: A Minecraft Server, Users: 0/20)
```

### 5. Tear down (when done)

```bash
cd terraform
terraform destroy
```

---

## Connecting to the Minecraft Server

1. Open **Minecraft Java Edition** (version 1.21.1)
2. Click **Multiplayer → Add Server**
3. Enter the server address: `<instance_public_ip>` (port 25565 is the default and does not need to be specified)
4. Click **Done**, then **Join Server**

---

## Auto-start and Clean Shutdown

The Minecraft server runs as a `systemd` service, which means:

- It **starts automatically** when the EC2 instance boots
- It **restarts on failure** (`Restart=on-failure` in the service definition)
- It **shuts down cleanly** when the instance stops, because systemd sends `SIGTERM` to the process and waits for it to exit gracefully before the system halts

The relevant service configuration is in [`ansible/templates/minecraft.service.j2`](ansible/templates/minecraft.service.j2).

---

## Notes

- The EC2 instance runs **Amazon Linux 2**, which reaches end-of-life on June 30, 2026. Consider migrating to Amazon Linux 2023 for longer-term deployments.
- The `vockey.pem` private key is excluded from version control via `.gitignore`. Never commit private keys to Git.
- Learner Lab session tokens expire periodically. If Terraform or Ansible fails with an auth error, refresh your credentials from the Learner Lab and re-export them.
