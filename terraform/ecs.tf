//# ecs.tf
//
//resource "aws_ecs_cluster" "main" {
//  name = "tutorial-bluegreen-cluster"
//}
//
//data "template_file" "cb_app" {
//  template = file("./templates/ecs/cb_app.json.tpl")
//
//  vars = {
//    app_image      = var.app_image
//    app_port       = var.app_port
//    fargate_cpu    = var.fargate_cpu
//    fargate_memory = var.fargate_memory
//    aws_region     = var.aws_region
//  }
//}
//
//resource "aws_ecs_task_definition" "app" {
//  family                   = "cb-app-task"
//  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
//  network_mode             = "awsvpc"
//  requires_compatibilities = ["FARGATE"]
//  cpu                      = var.fargate_cpu
//  memory                   = var.fargate_memory
//  container_definitions    = data.template_file.cb_app.rendered
//}
//
//resource "aws_ecs_service" "main" {
//  name            = "service-bluegreen"
//  cluster         = aws_ecs_cluster.main.id
//  task_definition = aws_ecs_task_definition.app.arn
//  desired_count   = 1
//  launch_type     = "FARGATE"
//  scheduling_strategy = "REPLICA"
//  deployment_controller {type = "CODE_DEPLOY"}
//  platform_version = "LATEST"
//
//  network_configuration {
//    security_groups  = [aws_security_group.ecs_tasks.id]
//    subnets          = aws_subnet.private.*.id
//    assign_public_ip = true
//  }
//
//  load_balancer {
//    target_group_arn = aws_alb_target_group.bluegreentarget1.id
//    container_name   = "cb-app"
//    container_port   = var.app_port
//  }
//
//  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]
//}
//
//resource "aws_codedeploy_app" "tutorial-bluegreen-app" {
//  name = "tutorial-bluegreen-app"
//}
//
//
//resource "aws_codedeploy_deployment_group" "tutorial-bluegreen-app" {
//  app_name = "tutorial-bluegreen-app"
//  deployment_group_name = "tutorial-bluegreen-dg"
//  service_role_arn = "arn:aws:iam::aws_account_id:role/ecsCodeDeployRole"
//  ecs_service {
//    cluster_name = "service-bluegreen"
//    service_name = "tutorial-bluegreen-cluster"
//  }
//  auto_rollback_configuration {
//    enabled = true
//    events = ["DEPLOYMENT_FAILURE"]
//  }
//  blue_green_deployment_config {
//    deployment_ready_option {
//      action_on_timeout = "CONTINUE_DEPLOYMENT"
//      wait_time_in_minutes = 0
//    }
//    terminate_blue_instances_on_deployment_success {
//      action = "TERMINATE"
//      termination_wait_time_in_minutes = 5
//    }
//  }
//  deployment_style {
//    deployment_option = "WITH_TRAFFIC_CONTROL"
//    deployment_type = "BLUE_GREEN"
//  }
//  load_balancer_info {
//    target_group_pair_info {
//      prod_traffic_route {
//        listener_arns = []
//      }
//      target_group {
//        name = ["bluegreentarget1","bluegreentarget2"]
//      }
//    }
//  }
//}