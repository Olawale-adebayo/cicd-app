resource "aws_ecr_repository" "app" {
  name         = var.app_name
  force_delete = true # lets `terraform destroy` remove it even with images inside

  image_scanning_configuration {
    scan_on_push = true
  }
}