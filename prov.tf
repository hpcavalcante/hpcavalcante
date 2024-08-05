provider "aws" {
  region = "us-east-1"  # Escolha a região adequada para você
}

# Configurar as variáveis para a VPC e grupos de segurança existentes
variable "vpc_id" {
  description = "ID da VPC existente"
  type        = string
}

variable "security_group_id" {
  description = "ID do grupo de segurança existente"
  type        = string
}

# Criar Application Load Balancer (ALB)
resource "aws_lb" "internal_alb" {
  name               = "internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = aws_subnet.public.*.id  # Subnets existentes

  enable_deletion_protection = false

  tags = {
    Name = "internal-alb"
  }
}

# Criar Target Group para o ALB
resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = 4231 # A porta do serviço
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"  # Endpoint de verificação de integridade
    interval            = 30
    timeout             = 5
    healthy_threshold  = 3
    unhealthy_threshold = 3
  }
}

# Criar listener para o ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}

# Criar Network Load Balancer (NLB)
resource "aws_lb" "nlb" {
  name               = "nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [var.security_group_id]
  subnets            = aws_subnet.public.*.id  # Subnets existentes

  enable_deletion_protection = false

  tags = {
    Name = "nlb"
  }
}

# Criar Target Group para o NLB
resource "aws_lb_target_group" "nlb_target_group" {
  name     = "nlb-target-group"
  port     = 80  # A porta do NLB
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

# Criar listener para o NLB
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group.arn
  }
}

# Criar VPC Link para o API Gateway
resource "aws_api_gateway_vpc_link" "vpc_link" {
  name        = "my-vpc-link"
  target_arn  = aws_lb.nlb.arn

  tags = {
    Name = "my-vpc-link"
  }
}

# Criar VPC Endpoint para o API Gateway
resource "aws_vpc_endpoint" "api_gateway_endpoint" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.us-east-1.execute-api"  # Altere para a região adequada
  route_table_ids    = aws_route_table.main.*.id  # Adapte para suas rotas

  policy = <<EOF
{
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "*"
    }
  ]
}
EOF
}

# Criar o serviço ECS
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "my-ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  memory                  = "512"
  cpu                     = "256"

  container_definitions = jsonencode([
    {
      name      = "my-container"
      image     = "my-docker-image"  # Substitua pela sua imagem
      portMappings = [
        {
          containerPort = 4231
          hostPort      = 4231
          protocol      = "tcp"
        },
        {
          containerPort = 4322
          hostPort      = 4322
          protocol      = "tcp"
        },
        {
          containerPort = 8888
          hostPort      = 8888
          protocol      = "tcp"
        },
        {
          containerPort = 8889
          hostPort      = 8889
          protocol      = "tcp"
        },
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public.*.id  # Adapte para suas subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "my-container"
    container_port   = 4231
  }
}
