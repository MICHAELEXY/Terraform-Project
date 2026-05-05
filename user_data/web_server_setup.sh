#!/bin/bash
set -e   #handle error

# Log everything
exec > /var/log/web_server-setup.log 2>&1

# Wait for NAT / internet to stabilize
sleep 60

echo "Starting web server setup..."

# Update system
yum update -y
yum install -y httpd
# Ensure SSH service is running (already installed on Amazon Linux)
systemctl start httpd
systemctl enable httpd

echo "SSH service is running"
echo "Web server setup complete"
echo "Hello from $(hostname)" > /var/www/html/index.html