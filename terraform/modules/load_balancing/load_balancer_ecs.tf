
resource "aws_lb" "main" {
  name               = "frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = [var.public_subnet_1_id, var.public_subnet_2_id]
 
  enable_deletion_protection = false
}
 
resource "aws_alb_target_group" "main" {
  name        = "frontend-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
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
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_role_arn
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
   security_groups  = [var.project_security_group_id]
   subnets          = [var.seismic_subnet_id]
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