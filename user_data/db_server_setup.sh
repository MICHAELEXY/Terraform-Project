#!/bin/bash
set -e

# Log everything
exec > /var/log/db-setup.log 2>&1

echo "Starting PostgreSQL setup..."

# Update system
yum update -y

# Enable PostgreSQL 14
amazon-linux-extras enable postgresql14

# Install PostgreSQL 14
yum install -y postgresql14-server

# Initialize database
postgresql-setup initdb

# Start and enable service
systemctl start postgresql
systemctl enable postgresql

echo "PostgreSQL installation complete"