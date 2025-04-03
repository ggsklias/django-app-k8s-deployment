resource "aws_lb" "app_alb" {
  name               = "k8s-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh_and_k8s.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Environment = var.environment
    Application = "djangoarticleapp"
  }
}

output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "The DNS name of the application ALB"
}

resource "aws_lb_target_group" "app_tg" {
  name_prefix = "k8tg-"
  port        = tonumber(var.node_port)
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol            = "HTTP"
    path                = "/healthz"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }

}

locals {
  # Convert the tuple to a map with indices as keys.
  worker_instance_map = { for idx, instance_id in module.workers.instance_ids : idx => instance_id }
}

resource "aws_lb_target_group_attachment" "worker_attachments" {
  for_each         = local.worker_instance_map
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = each.value
  port             = var.node_port
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.app_tg]

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.app_tg.arn
        weight = 100
      }
    }
  }
}