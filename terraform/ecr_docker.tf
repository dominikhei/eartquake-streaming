resource "aws_ecr_repository" "frontend_repository" {
  name = "earthquake-frontend"
}

resource "null_resource" "docker_packaging" {
    provisioner "local-exec" {
        command = <<EOF
            aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
            docker build -t earthquake_frontend:latest ./frontend
            docker tag earthquake_frontend:latest ${aws_ecr_repository.frontend_repository.repository_url}:latest
            docker push ${aws_ecr_repository.frontend_repository.repository_url}:latest
        EOF
    }

    depends_on = [
        aws_ecr_repository.frontend_repository,
    ]
}