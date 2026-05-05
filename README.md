# Terraform AWS Infrastructure - TechCorp

## 📌 Overview
This project provisions a highly available and secure AWS infrastructure using Terraform.

## 🧱 Resources Created
- VPC with public and private subnets
- Internet Gateway and NAT Gateways
- Bastion Host
- Web Servers (Apache)
- Database Server (PostgreSQL)
- Application Load Balancer

## ⚙️ Prerequisites
- Terraform installed
- AWS CLI configured
- AWS account
- Existing key pair in AWS

## 🚀 Deployment Steps

1. Clone the repository:
   git clone <your-repo-url>

2. Navigate into the project folder:
   cd terraform-assessment

3. Initialize Terraform:
   terraform init

4. Review execution plan:
   terraform plan

5. Apply configuration:
   terraform apply

## 🔐 Access

- SSH into Bastion:
  ssh -i <key.pem> ec2-user@<bastion-public-ip>

- From Bastion, access private servers

## 🌐 Load Balancer

Access the application using:
http://<alb-dns-name>

## 🧹 Destroy Infrastructure

To clean up resources:
terraform destroy

## 📸 Evidence

## Evidence
Screenshots are available in the `evidence/` folder.

## 👤 Author
Michaelexy