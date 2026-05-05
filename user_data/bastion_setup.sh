#!/bin/bash
set -e

# Log everything
exec > /var/log/bastion-setup.log 2>&1

echo "Starting bastion setup..."

# Update system
yum update -y

# Ensure SSH is running
systemctl enable sshd
systemctl start sshd

echo "Bastion setup complete"