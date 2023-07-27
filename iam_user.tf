resource "aws_iam_user" "cm" {
  name = "cluster_manager"
  path = "/system/"

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_access_key" "cm" {
  user = aws_iam_user.cm.name
}

data "aws_iam_policy_document" "cm_ro" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "cm_ro" {
  name   = "test"
  user   = aws_iam_user.cm.name
  policy = data.aws_iam_policy_document.cm_ro.json
}

output "secret" {
  value = aws_iam_access_key.cm.encrypted_secret
}