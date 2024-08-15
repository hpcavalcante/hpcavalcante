# NLB
resource "aws_lb" "nlb" {
  name               = "internal-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnets

  security_groups    = [aws_security_group.nlb_sg.id]
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "alb-target-group"
  port     = 443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  target_type = "alb"
}

# ALB
resource "aws_lb" "alb" {
  name               = "internal-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.subnets

  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "alb_listener_4321" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "4321"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg_4321.arn
  }
}

resource "aws_lb_listener" "alb_listener_4322" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "4322"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg_4322.arn
  }
}

resource "aws_lb_listener" "alb_listener_8888" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8888"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg_8888.arn
  }
}

resource "aws_lb_listener" "alb_listener_8889" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8889"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg_8889.arn
  }
}

resource "aws_lb_target_group" "ecs_tg_4321" {
  name     = "ecs-tg-4321"
  port     = 4321
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"
}

resource "aws_lb_target_group" "ecs_tg_4322" {
  name     = "ecs-tg-4322"
  port     = 4322
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"
}

resource "aws_lb_target_group" "ecs_tg_8888" {
  name     = "ecs-tg-8888"
  port     = 8888
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"
}

resource "aws_lb_target_group" "ecs_tg_8889" {
  name     = "ecs-tg-8889"
  port     = 8889
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"
}

# Security Group for NLB
resource "aws_security_group" "nlb_sg" {
  name        = "nlb-sg"
  vpc_id      = var.vpc_id

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
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 4321
    to_port     = 8889
    protocol    = "tcp"
    security_groups = [aws_security_group.nlb_sg.id]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for ECS Service
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 4321
    to_port     = 8889
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
