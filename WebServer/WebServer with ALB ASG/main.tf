# main.tf

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region = "ap-southeast-2"  # Sydney region
}

# Security Group definition
resource "aws_security_group" "webserver" {
  name        = "webserver"
  description = "Allow inbound HTTP traffic"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define EC2 instances
resource "aws_instance" "webserver1" {
  ami           = "ami-001f2488b35ca8aad"  # Ubuntu 24.04 on ap-southeast-2
  instance_type = "t2.micro"
  security_groups = [aws_security_group.webserver.name]
  tags = {
    Name = "webserver1"
  }
}

resource "aws_instance" "webserver2" {
  ami           = "ami-001f2488b35ca8aad"  # Ubuntu 24.04 on ap-southeast-2
  instance_type = "t2.micro"
  security_groups = [aws_security_group.webserver.name]
  tags = {
    Name = "webserver2"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "test-terraform-bucket-web-app-data"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Load Balancer
resource "aws_lb" "webserver_lb" {
  name               = "webserver_lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.subnets.ids
  security_groups   = [aws_security_group.webserver.id]
}

# Target Group for Load Balancer
resource "aws_lb_target_group" "instances" {
  name     = "instances"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

# Attach EC2 instances to the load balancer target group
resource "aws_lb_target_group_attachment" "webserver1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "webserver2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

# VPC and Subnets data sources
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "webserver" {
  name = "webserver-template"
  
  instance_type = "t2.micro"
  ami = "ami-001f2488b35ca8aad"  # Ubuntu 24.04 on ap-southeast-2
  
  security_group_names = [aws_security_group.webserver.name]
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > /var/www/html/index.html
              EOF
}

# Auto Scaling Group
resource "aws_autoscaling_group" "webserver_asg" {
  name                 = "webserver_asg"
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  health_check_grace_period = 300
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.instances.arn]
  vpc_zone_identifier  = data.aws_subnet_ids.subnets.ids
  launch_template {
    id      = aws_launch_template.webserver.id
    version = aws_launch_template.webserver.latest_version
  }
}

# RDS Database Subnet Group
resource "aws_db_subnet_group" "webserver_db_subnet_group" {
  name        = "webserver-db-subnet-group"
  description = "Subnet group for webserver database"
  subnet_ids  = data.aws_subnet_ids.subnets.ids
}

# RDS Database Instance
resource "aws_db_instance" "webserver_db" {
  allocated_storage       = 10
  engine                 = "mysql"
  engine_version         = "8.0.30"
  instance_class         = "db.t2.micro"
  username               = "XXXXX"  # Replace with DB username
  password               = "XXXXXXXX"  # Replace with DB password
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.webserver_db_subnet_group.name
}

# DynamoDB Table for State Locking (Required for Terraform backend)
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  hash_key       = "LockID"
  billing_mode   = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}

