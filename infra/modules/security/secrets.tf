# ---------------------------------------------------------------------------
# AWS Secrets Manager (optional scaffold)
# Creates a dedicated secret for application secrets without forcing any change
# to the current deployment unless explicitly enabled.
# ---------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "app" {
  count = var.enable_secrets_manager ? 1 : 0

  name                    = "${var.name_prefix}/grandnode/app"
  description             = "Application secrets for GrandNode (${var.name_prefix})"
  recovery_window_in_days = 7

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-secrets" })
}

resource "aws_secretsmanager_secret_version" "app" {
  count = var.enable_secrets_manager && var.app_secrets_json != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.app[0].id
  secret_string = var.app_secrets_json
}

data "aws_iam_policy_document" "app_secrets_read" {
  count = var.enable_secrets_manager ? 1 : 0

  statement {
    sid    = "ReadAppSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [aws_secretsmanager_secret.app[0].arn]
  }
}

resource "aws_iam_policy" "app_secrets_read" {
  count = var.enable_secrets_manager ? 1 : 0

  name        = "${var.name_prefix}-app-secrets-read"
  description = "Read-only access to GrandNode application secrets in AWS Secrets Manager."
  policy      = data.aws_iam_policy_document.app_secrets_read[0].json

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-secrets-read" })
}
