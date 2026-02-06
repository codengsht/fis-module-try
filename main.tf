# AWS FIS Experiment Template Module
# Core resources: FIS template, IAM role, CloudWatch alarms

# IAM assume role policy for FIS service principal
data "aws_iam_policy_document" "fis_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["fis.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM role for FIS experiment execution
resource "aws_iam_role" "fis" {
  name               = "${var.name_prefix}-fis-role"
  assume_role_policy = data.aws_iam_policy_document.fis_assume_role.json
  tags               = var.tags
}

# IAM policy attachment for FIS experiment execution permissions
resource "aws_iam_role_policy_attachment" "fis" {
  role       = aws_iam_role.fis.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorEC2Access"
}

# CloudWatch metric alarms for FIS experiment stop conditions
resource "aws_cloudwatch_metric_alarm" "stop_condition" {
  for_each = { for idx, sc in var.stop_conditions : sc.alarm_name => sc }

  alarm_name          = "${var.name_prefix}-${each.value.alarm_name}"
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  statistic           = each.value.statistic
  period              = each.value.period
  threshold           = each.value.threshold
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  dimensions          = each.value.dimensions
  alarm_description   = each.value.alarm_description

  tags = var.tags
}
# FIS Experiment Template - base resource
# Dynamic blocks for actions, targets, stop_conditions, and log_configuration
# will be added in tasks 6.2-6.5
resource "aws_fis_experiment_template" "this" {
  description = var.description
  role_arn    = aws_iam_role.fis.arn

  # Dynamic action blocks - iterates over actions variable
  dynamic "action" {
    for_each = var.actions
    content {
      name        = action.value.name
      action_id   = action.value.action_id
      description = action.value.description

      # Nested dynamic parameter block for optional parameters
      dynamic "parameter" {
        for_each = action.value.parameters != null ? action.value.parameters : {}
        content {
          key   = parameter.key
          value = parameter.value
        }
      }

      # Nested dynamic target block for optional target reference
      dynamic "target" {
        for_each = action.value.target != null ? [action.value.target] : []
        content {
          key   = action.value.name
          value = target.value
        }
      }

      start_after = action.value.start_after
    }
  }

  # Dynamic target blocks - iterates over targets variable
  dynamic "target" {
    for_each = var.targets
    content {
      name           = target.value.name
      resource_type  = target.value.resource_type
      selection_mode = target.value.selection_mode
      resource_arns  = target.value.resource_arns

      # Nested dynamic resource_tag block for optional tags
      dynamic "resource_tag" {
        for_each = target.value.resource_tags != null ? target.value.resource_tags : {}
        content {
          key   = resource_tag.key
          value = resource_tag.value
        }
      }

      # Nested dynamic filter block for optional filters
      dynamic "filter" {
        for_each = target.value.filters != null ? target.value.filters : []
        content {
          path   = filter.value.path
          values = filter.value.values
        }
      }
    }
  }

  # Dynamic stop_condition blocks - iterates over stop_conditions variable
  # References CloudWatch alarm ARNs created by aws_cloudwatch_metric_alarm.stop_condition
  dynamic "stop_condition" {
    for_each = var.stop_conditions
    content {
      source = "aws:cloudwatch:alarm"
      value  = aws_cloudwatch_metric_alarm.stop_condition[stop_condition.value.alarm_name].arn
    }
  }

  # Dynamic log_configuration block - conditionally included when logging is configured
  dynamic "log_configuration" {
    for_each = (var.s3_logging_configuration != null || var.cloudwatch_logging_configuration != null) ? [1] : []
    content {
      log_schema_version = 2

      dynamic "s3_configuration" {
        for_each = var.s3_logging_configuration != null ? [var.s3_logging_configuration] : []
        content {
          bucket_name = s3_configuration.value.bucket_name
          prefix      = s3_configuration.value.prefix
        }
      }

      dynamic "cloudwatch_logs_configuration" {
        for_each = var.cloudwatch_logging_configuration != null ? [var.cloudwatch_logging_configuration] : []
        content {
          log_group_arn = cloudwatch_logs_configuration.value.log_group_arn
        }
      }
    }
  }

  tags = var.tags
}
