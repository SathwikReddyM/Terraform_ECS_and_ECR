provider "aws" {
  version = "~> 2.0"
  region  = "us-east-2" # Setting my region to Ohio. Use your own region here
}
/*
resource "aws_ecr_repository" "flask" {
  name = "flask-repo" # Naming my repository
}*/

resource "aws_ecs_cluster" "cluster" {
  name = "flask-cluster" # Naming the cluster
}

#907741976969.dkr.ecr.us-east-2.amazonaws.com/flask-repo:latest
#"image": "${aws_ecr_repository.flask.repository_url}:latest",
resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "flask-task",
      "image": "907741976969.dkr.ecr.us-east-2.amazonaws.com/flask-repo:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 5000
        }
      ],"logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "example",
                    "awslogs-region": "us-east-2",
                    "awslogs-stream-prefix": "awslogs-example"
                }
            },
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-2a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-2b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "us-east-2c"
}

resource "aws_ecs_service" "flask_service" {
  name            = "my-flask-service"                             # Naming our first service
  cluster         = "${aws_ecs_cluster.cluster.id}"             # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.flask_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers to 3

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Setting the security group
  }
}


resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    //security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

/*output "name" {
  value = aws_ecr_repository.flask.repository_url
}*/
