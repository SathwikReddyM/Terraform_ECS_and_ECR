terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  alias = "us-east-2"
  region = "us-east-2"
  //access_key = "AKIAVONCJ7TZCXBHQPZV"
  //secret_key = "o80djT6HtntUbvCfYlhb8X1lfoHWrMtMr4/qPFzw"
  access_key = "Your_key"
  secret_key = "Your_key"
}

resource "aws_default_vpc" "my-personal-web" {
  provider = aws.us-east-2
  tags = {
    env = "dev"
  }
}

resource "aws_default_subnet" "my-personal-web" {
  provider          = aws.us-east-2
  availability_zone = "us-east-2a"
  tags = {
    env = "dev"
  }
}
resource "aws_default_subnet" "my-personal-web-1" {
  provider          = aws.us-east-2
  availability_zone = "us-east-2b"
  tags = {
    env = "dev"
  }
}

resource "aws_security_group" "my-personal-web" {
  provider = aws.us-east-2
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_default_vpc.my-personal-web.id

  ingress {
    description = "Allow HTTP for all"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow HTTP for all"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "my-personal-web" {
  provider = aws.us-east-2
  name     = "my-personal-web-api-cluster"
}

resource "aws_ecs_task_definition" "my-personal-web" {
  provider = aws.us-east-2
  family = "service"
  container_definitions = jsonencode([
    {
      "name" = "nginx_container",
      image = "ubuntu"
    }
  ])
}

resource "aws_ecs_service" "my-personal-web" {
  provider = aws.us-east-2

  name            = "my-personal-web"
  cluster         = aws_ecs_cluster.my-personal-web.id
  task_definition = aws_ecs_task_definition.my-personal-web.arn
  desired_count   = 1


  network_configuration {
    subnets          = [aws_default_subnet.my-personal-web.id, aws_default_subnet.my-personal-web-1.id]
    security_groups  = [aws_security_group.my-personal-web.id]
    assign_public_ip = true
  }
  tags = {
    env = "dev"
  }
}