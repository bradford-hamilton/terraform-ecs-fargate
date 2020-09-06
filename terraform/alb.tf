# alb.tf

resource "aws_alb" "bluegreen-alb" {
  name = "bluegreen-alb"
  subnets = aws_subnet.public.*.id
  security_groups = [
    aws_security_group.lb.id]
}

resource "aws_alb_target_group" "bluegreentarget1" {
  name = "bluegreentarget1"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold = "3"
    interval = "30"
    protocol = "HTTP"
    matcher = "200"
    timeout = "3"
    path = var.health_check_path
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_target_group" "bluegreentarget2" {
  name = "bluegreentarget2"
  port = 81
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold = "3"
    interval = "30"
    protocol = "HTTP"
    matcher = "200"
    timeout = "3"
    path = var.health_check_path
    unhealthy_threshold = "2"
  }
}


# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.bluegreen-alb.arn
  port = var.app_port
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.bluegreentarget1.id
    type = "forward"
  }
}

resource "aws_alb_listener" "front_green" {
  load_balancer_arn = aws_alb.bluegreen-alb.arn
  port = 3001
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.bluegreentarget2.id
    type = "forward"
  }
}


# ecs.tf

resource "aws_ecs_cluster" "main" {
  name = "tutorial-bluegreen-cluster"
}

data "template_file" "cb_app" {
  template = file("./templates/ecs/cb_app.json.tpl")

  vars = {
    app_image = var.app_image
    app_port = var.app_port
    fargate_cpu = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region = var.aws_region
  }
}

resource "aws_ecs_task_definition" "app" {
  family = "tutorial-task-def"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.fargate_cpu
  memory = var.fargate_memory
  container_definitions = data.template_file.cb_app.rendered
}

resource "aws_ecs_service" "main" {
  name = "service-bluegreen"
  cluster = "tutorial-bluegreen-cluster"
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 1
  launch_type = "FARGATE"
  scheduling_strategy = "REPLICA"

  lifecycle {
    ignore_changes = [desired_count]
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.bluegreentarget1.arn
    container_name = "service-bluegreen"
    container_port = var.app_port
  }

}


resource "aws_codedeploy_app" "tutorial-bluegreen-app" {
  name = "tutorial-bluegreen-app"
  compute_platform = "ECS"
}

resource "aws_sns_topic" "deployment-start" {
  name = "deployment-start"
}

resource "aws_sns_topic" "deployment-success" {
  name = "deployment-success"
}

resource "aws_sns_topic" "deployment-failure" {
  name = "deployment-failure"
}







resource "aws_codedeploy_deployment_group" "tutorial-bluegreen-dg" {

  app_name = aws_codedeploy_app.tutorial-bluegreen-app.name
  deployment_group_name = "tutorial-bluegreen-dg"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  trigger_configuration {
    trigger_events     = ["DeploymentStart"]
    trigger_name       = "deployment-start-trigger"
    trigger_target_arn = aws_sns_topic.deployment-start.arn
  }

  trigger_configuration {
    trigger_events     = ["DeploymentSuccess"]
    trigger_name       = "deployment-success-trigger"
    trigger_target_arn = aws_sns_topic.deployment-success.arn
  }

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "deployment-failure-trigger"
    trigger_target_arn = aws_sns_topic.deployment-failure.arn
  }

  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
    }
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type = "BLUE_GREEN"
  }
  load_balancer_info {

    target_group_pair_info {
      target_group {
        name = "bluegreentarget1"
      }
      target_group {
        name = "bluegreentarget2"
      }
      prod_traffic_route {
        listener_arns = [aws_alb_listener.front_end.arn]
      }

      test_traffic_route {
        listener_arns = [aws_alb_listener.front_green.arn]
      }

    }
  }
  service_role_arn = "arn:aws:iam::967474675298:role/CodeDeploy"
  ecs_service {
    service_name = aws_ecs_service.main.name
    cluster_name = aws_ecs_cluster.main.name
  }
}

resource "aws_s3_bucket" "deployment_definition_bucket" {
  bucket = "blue-green-ecs-deployment-bucket"
}

resource "aws_s3_bucket_object" "depolyment_definition" {
  bucket = aws_s3_bucket.deployment_definition_bucket.id
  key = "appsec.yaml"
  source = "/Users/bharatmehta/self/terraform-ecs-fargate/terraform/templates/deployment/appsec.yaml"
}
//data "template_file" "deployment_revision" {
//  template = file("./templates/deployment/deployment.json.tpl")
//  vars = {
//    app_name = aws_codedeploy_deployment_group.tutorial-bluegreen-dg.app_name
//    deployment_group_name = aws_codedeploy_deployment_group.tutorial-bluegreen-dg.deployment_group_name
//  }
//}
//
//
//resource null_resource "trigger_code_deployment" {
//  provisioner "local-exec" {
////   command = "aws deploy create-deployment --profile tfuser --cli-input-json '${data.template_file.deployment_revision.rendered}' --region eu-central-1"
//   command = "  aws deploy create-deployment --cli-input-json file:///Users/bharatmehta/self/terraform-ecs-fargate/terraform/templates/deployment/deployment.json"
//  }
//  depends_on = [aws_codedeploy_app.tutorial-bluegreen-app,
//    aws_codedeploy_deployment_group.tutorial-bluegreen-dg,
//    aws_ecs_service.main]
//}