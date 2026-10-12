resource "aws_lb" "app" {
  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

# Target group: the list of containers the load balancer sends traffic to
resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip" # required for Fargate
  vpc_id      = aws_vpc.main.id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

# Listener: "when traffic arrives on port 80, forward it to the target group"
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}