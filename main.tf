terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.14.8"
}

# Configure the AWS Provider
#------------------------------
provider "aws" {
  region = var.region
}

# vpc setup
#------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "techcorp-vpc"
  }
}

# public vpc subnet setup
#---------------------------
resource "aws_subnet" "techcorp_public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "techcorp_public_subnet_1"
  }
}

resource "aws_subnet" "techcorp_public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "techcorp_public_subnet_2"
  }
}


# private vpc subnet setup
#-----------------------------------------------------
resource "aws_subnet" "techcorp_private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "techcorp_private_subnet_1"
  }
}


resource "aws_subnet" "techcorp_private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "techcorp_private_subnet_2"
  }
}


# Internet gateway
#---------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "techcorp-igw"
  }
}

# Internet gateway route table
#---------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "tech_public_rt"
  }
}

# Associating the Internet route table to the public subnet
#--------------------------------------------------------------
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.techcorp_public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.techcorp_public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP for NAT Gateway
#--------------------------------
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
}

resource "aws_eip" "nat_eip_2" {
  domain = "vpc"
}

# NAT Gateways (One per Public Subnet)
#----------------------------------------
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.techcorp_public_subnet_1.id
  tags = {
    Name = "techcorp-nat-1"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.techcorp_public_subnet_2.id
  tags = {
    Name = "techcorp-nat-2"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private Route Tables
#-----------------------------
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name = "techcorp-private-rt-1"
  }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "techcorp-private-rt-2"
  }
}

# Associate Private Route Tables
#------------------------------------
resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.techcorp_private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.techcorp_private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}

#Security group
#--------------------
# Bastion host security group
#-------------------------------
resource "aws_security_group" "bastion_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "techcorp-bastion-sg"
  description = "Allow SSH to Bastion - TEMPORARY"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
    description = "SSH Access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techcorp-bastion-sg"
  }
}

# Web servers security group
#------------------------------
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
  name        = "techcorp-web-sg"
  description = "Security group for Web Servers (EC2 instances)"
 

# Allow traffic ONLY from the ALB on port 80, 443, and bastion host
#------------------------------------------------------------------
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow HTTP from ALB only"
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow HTTPS from ALB only"
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "Allow SSH from Bastion"
  }
  # Allow all outbound traffic (needed for updates, package downloads, etc.)  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
  tags = {
    Name = "techcorp-web-sg"
  }

}

# Database security group
#-------------------------------
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  security_groups = [aws_security_group.bastion_sg.id]
}
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}

# Load balancer Security group
resource "aws_security_group" "alb_sg" {
   vpc_id = aws_vpc.main.id
   name        = "techcorp-alb-sg"
   description = "Security group for Application Load Balancer"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
}
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

    tags = {
    Name = "techcorp-alb-sg"
  }
}


#EC2 Instances
#-------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]

  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.techcorp_public_subnet_1.id
  user_data = file("user_data/bastion_setup.sh")
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
  Name        = "Bastion_host"
  Environment = "dev"
  Project     = "techcorp"
}
}

resource "aws_instance" "web" {
  count         = 2
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = element([aws_subnet.techcorp_private_subnet_1.id, aws_subnet.techcorp_private_subnet_2.id], count.index)
  user_data = file("user_data/web_server_setup.sh")
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
  Name        = "web-server-${count.index + 1}"
  Environment = "dev"
  Project     = "techcorp"
}

}

resource "aws_instance" "db" {
  ami           = data.aws_ami.amazon_linux.id                                                                
  instance_type = var.db_instance_type
  subnet_id     = aws_subnet.techcorp_private_subnet_1.id
  user_data = file("user_data/db_server_setup.sh")
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "postgresDB"
  }
}

#Load Balancer
#----------------------
resource "aws_lb" "alb" {
  name               = "techcorp-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.techcorp_public_subnet_1.id, aws_subnet.techcorp_public_subnet_2.id]
  security_groups = [aws_security_group.alb_sg.id]
  tags               = { Name = "TechCorp-ALB" }
}

# Target group for load balancer
#-----------------------------------
resource "aws_lb_target_group" "tg" {
  name     = "LB-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"

  health_check { 
    enabled             = true
    path                = "/"                  
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"            
  }

    tags = {
    Name = "LB-tg"
  }
}

# Alb target group attachment
#--------------------------------------

resource "aws_lb_target_group_attachment" "web_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

#Alb listener
#----------------

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80   
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}