# ------------------------------------------------------------------------------
# FinOps : budget AWS et alertes (optionnel, activé via var.finops_budget_enabled).
# ------------------------------------------------------------------------------

# Budget mensuel (coût) — créé seulement si finops_budget_enabled = true et au moins un email dans finops_budget_alert_emails.
resource "aws_budgets_budget" "project" {
  count = var.finops_budget_enabled && length(var.finops_budget_alert_emails) > 0 ? 1 : 0

  name              = "${var.project_name}-${var.environment}-monthly"
  budget_type       = "COST"
  limit_amount      = tostring(var.finops_budget_amount_usd)
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  # Alerte à 60 % du budget réel ( coût effectif).
 notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 60
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.finops_budget_alert_emails
  }

  # Alerte à 80 % du budget réel (coût effectif).
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.finops_budget_alert_emails
  }

  # Alerte à 100 % du budget réel (dépassement).
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.finops_budget_alert_emails
  }

  # Alerte si la prévision dépasse 120 % du budget (FORECASTED).
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 120
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.finops_budget_alert_emails
  }
}
