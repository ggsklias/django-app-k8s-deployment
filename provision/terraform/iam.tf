resource "aws_iam_role" "ci_infrastructure_access" {
  name               = "ci_infrastructure_access"
  assume_role_policy = file("trust_policy.json")
}

resource "aws_iam_instance_profile" "ci_infrastructure_access" {
  name = "ci_infrastructure_access"
  role = aws_iam_role.ci_infrastructure_access.name
}

resource "aws_iam_role_policy" "elb_policy" {
  name   = "AllowELBDescribeTargetHealth"
  role   = aws_iam_role.ci_infrastructure_access.id
  policy = file("elb_policy.json")
}

resource "aws_iam_role_policy" "describe_instances_policy" {
  name   = "AllowDescribeInstances"
  role   = aws_iam_role.ci_infrastructure_access.id
  policy = file("describe_instances_policy.json")
}

resource "aws_iam_role_policy" "get_secret_policy" {
  name   = "AllowGetSecretValue"
  role   = aws_iam_role.ci_infrastructure_access.id
  policy = file("get_secret_policy.json")
}