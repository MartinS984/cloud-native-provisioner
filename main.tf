# --- main.tf ---

#  Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecommerce-capstone-vpc"
  }
}

#  Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecommerce-public-subnet-1a"
  }
}

#  Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ecommerce-igw"
  }
}

#  Create a Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ecommerce-public-rt"
  }
}

#  Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#  Create a Security Group
resource "aws_security_group" "web_sg" {
  name        = "ecommerce-web-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-web-sg"
  }
}

# --- Phase 7: Auto Scaling Group & Launch Template ---

# 1. Launch Template (The blueprint for new EC2 instances)
resource "aws_launch_template" "web_template" {
  name_prefix   = "ecommerce-web-template-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  # The installation script for Apache with IMDSv2 AZ fetching
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              
              # Fetch the Availability Zone from AWS Metadata
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
              
              # Write the AZ into the webpage
              echo "<h1>Cloud-Native Provisioner is Live via ASG!</h1><p>Traffic successfully routed to Availability Zone: <b>$AZ</b></p>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecommerce-asg-web-server"
    }
  }
}

# 2. Auto Scaling Group (The engine that manages the instances)
resource "aws_autoscaling_group" "web_asg" {
  name                = "ecommerce-web-asg"
  desired_capacity    = 2 # We want 2 servers running at all times
  max_size            = 3 # Scale up to 3 if traffic spikes
  min_size            = 1 # Never drop below 1
  vpc_zone_identifier = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }
}

#  Fetch the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


#  Second Public Subnet (in a different AZ)
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "us-east-1b" # Must be different from us-east-1a
  map_public_ip_on_launch = true

  tags = {
    Name = "ecommerce-public-subnet-1b"
  }
}

#  Route Table Association for the second subnet
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

#  Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "ecommerce-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "ecommerce-alb"
  }
}

#  Target Group (Where the ALB sends traffic)
resource "aws_lb_target_group" "web_tg" {
  name     = "ecommerce-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}



#  ALB Listener (Rules for incoming traffic)
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
