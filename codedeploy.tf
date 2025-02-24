resource "aws_codedeploy_app" "webapp" {
  compute_platform = "Server"
  name             = "webapp"
}

resource "aws_codedeploy_deployment_group" "example" {
  app_name              = aws_codedeploy_app.example.name
  deployment_group_name = "example-group"
  service_role_arn      = aws_iam_role.codedeploy.arn

  autoscaling_groups = [aws_autoscaling_group.webapp_asg.name] # ⚠️ Check if this is valid in your case

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.example.name
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}

