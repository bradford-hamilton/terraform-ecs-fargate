data "aws_iam_policy_document" "ecsTaskExecutionRole" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = var.ecsTaskExecutionRoleName
  assume_role_policy = data.aws_iam_policy_document.ecsTaskExecutionRole.json
}

#EASY FETCH OF POLICY DOCUMENT FROM OFFICIAL POLICY ARN. THIS WAY WE SPARE A RESOURCE.
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecsAutoScaleRole" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsAutoScaleRole" {
  name               = var.ecsAutoScaleRoleName
  assume_role_policy = data.aws_iam_policy_document.ecsAutoScaleRole.json
}

#EASY FETCH OF POLICY DOCUMENT FROM OFFICIAL POLICY ARN. THIS WAY WE SPARE A RESOURCE.
resource "aws_iam_role_policy_attachment" "ecsAutoScaleRole" {
  role       = aws_iam_role.ecsAutoScaleRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}