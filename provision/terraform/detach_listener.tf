resource "aws_lb_listener" "app_listener_detach" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service temporarily unavailable"
      status_code  = "503"
    }
  }
}
