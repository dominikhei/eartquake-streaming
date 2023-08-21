
resource "aws_lb" "main" {
  name               = "frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
 
  enable_deletion_protection = false
}
 
resource "aws_alb_target_group" "main" {
  name        = "frontend-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.seismic-project-vpc.id
  target_type = "ip"
 
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
 
  default_action {
    target_group_arn = aws_alb_target_group.main.arn
    type             = "forward"
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.seismic_cluster.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
 
  target_tracking_scaling_policy_configuration {
   predefined_metric_specification {
     predefined_metric_type = "ECSServiceAverageMemoryUtilization"
   }
   target_value       = 90
  }
}

resource "aws_ecs_cluster" "seismic_cluster" {
  name = "seismic-ecs-cluster"
}

resource "aws_ecs_task_definition" "earthquake_frontend_task" {
  family                   = "frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_role.arn
  container_definitions = jsonencode([{
   name        = "frontend-container"
   image       = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/earthquake-frontend:latest"
   essential   = true
   network_mode = "awsvpc"
   portMappings = [{
     protocol      = "tcp"
     containerPort = 8501
     hostPort      = 8501
    }]
  }])
}

resource "aws_ecs_service" "main" {
 name                               = "earthquake-frontend-service"
 cluster                            = aws_ecs_cluster.seismic_cluster.id
 task_definition                    = aws_ecs_task_definition.earthquake_frontend_task.arn
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"
 
 network_configuration {
   security_groups  = [aws_security_group.project_security_group.id]
   subnets          = [aws_subnet.seismic-subnet.id]
   assign_public_ip = true
 }
 
 load_balancer {
   target_group_arn = aws_alb_target_group.main.arn
   container_name   = "frontend-container"
   container_port   = 8501
 }
 depends_on = [
    aws_alb_target_group.main
 ]
}