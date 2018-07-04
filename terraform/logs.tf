resource "aws_cloudwatch_log_group" "cb_log_group" {
  name              = "/ecs/app"
  retention_in_days = 30

  tags {
    Name = "cb_log_group"
  }
}

resource "aws_cloudwatch_log_stream" "cb_log_stream" {
  name           = "cb_log_stream"
  log_group_name = "${aws_cloudwatch_log_group.cb_log_group.name}"
}
