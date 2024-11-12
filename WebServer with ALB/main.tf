#main.tf 

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }

    #provider
    provider "aws" {
        region = "ap-southeast-2" #sydney
        }

    #backend
    backend "s3" {
        bucket = "test-terraform-bucket"
        key = "terraform.tfstate"
        region = "ap-southeast-2"
        dynamodb_table = "terraform-state-lock"
        encrypt = true
    }

    #resource
    resource "aws_instance" "webserver1" {
        ami = "ami-001f2488b35ca8aad" #Ubuntu 24.04 LTS 
        instance_type = "t2.micro"
        security_groups = "webserver"
        tags = {
            Name = "webserver1"
        }
    }

    resource "aws_instance" "webserver2" {
        ami = "ami-001f2488b35ca8aad" #Ubuntu 24.04 LTS 
        instance_type = "t2.micro"
        security_groups = "webserver"
        tags = {
            Name = "webserver2"
        }
    }

    resource "aws_s3_bucket" "bucket" {
        bucket_prefix ="test-terraform-bucket-web-app-data"
        force_destroy = true
    }
    
    data "aws_vpc" "default_vpc" {
        default = true
    }

    data "aws_subnet_ids" "subnets" {
        vpc_id = data.aws_vpc.default_vpc.id
    }   

    resource "aws_s3_bucket_versioning" "versioning" {
        bucket = aws_s3_bucket.bucket.id
        versioning_configuration {
            status = "Enabled"
        }
    }

    resource "aws_security_group" "webserver" {
        name = "webserver"
        description = "Allow inbound HTTP traffic"
        ingress {
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    resource "aws_lb_listener" "http_listener" {
        load_balancer_arn = aws_lb.webserver.arn
        port = 80
        protocol = "HTTP"
        default_action {
            type = "redirect"
            redirect {
                port = "443"
                protocol = "HTTPS"
                status_code = "HTTP_301"
            }
        }
    }

    resource "aws_lb_target_group" "instances" {
        name = "instances"
        port = 80
        protocol = "HTTP"
        vpc_id = data.aws_vpc.default_vpc.id
    
    health_check {
        enabled = true
        interval = 30
        path = "/"
        port = 80
        protocol = "HTTP"
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
        matcher = "200-299"
        }
    }

    resource "aws_lb_target_group_attachment" "webserver1" {
        target_group_arn = aws_lb_target_group.instances.arn
        target_id = aws_instance.webserver1.id
        port = 80
    }

    resource "aws_lb_target_group_attachment" "webserver2" {
        target_group_arn = aws_lb_target_group.instances.arn
        target_id = aws_instance.webserver2.id
        port = 80
    }

    resource "aws_security_group_rule" "allow_all" {
        type = "egress"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        security_group_id = aws_security_group.webserver.id

        type = "ingress"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        security_group_id = aws_security_group.webserver.id
    }

    resource "aws_lb" "webserver_balancer" {
        name = "webserver_lb"
        load_balancer_type = "application"
        subnets = data.aws_subnet_ids.subnets.ids
        security_groups = [aws_security_group.webserver.id]
    }

    resource "aws_db_instance" "webserver_db" {
        allocated_storage = 10
        engine = "mysql"
        engine_version = "8.0.30"
        instance_class = "db.t2.micro"
        username = "XXXXX"
        password = "XXXXXXXX"
        skip_final_snapshot = true
        db_subnet_group_name = "webserver_db_subnet_group"
    }

}



