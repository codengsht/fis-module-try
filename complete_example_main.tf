# Complete FIS Experiment Template Example
#
# This example demonstrates all features of the FIS module including:
# - Multiple actions with start_after dependencies
# - Multiple targets with different selection modes
# - Stop conditions with CloudWatch metric alarms
# - S3 logging configuration
# - CloudWatch logging configuration
# - Resource tagging

provider "aws" {
  region = "us-east-1"
}

# Data source to get existing IAM role for FIS
data "aws_iam_role" "fis" {
  name = "fis-experiment-role"  # Replace with your existing FIS role name
}

# S3 bucket for FIS experiment logs
resource "aws_s3_bucket" "fis_logs" {
  bucket_prefix = "fis-experiment-logs-"
  force_destroy = true

  tags = {
    Environment = "test"
    Project     = "fis-complete-example"
  }
}

# CloudWatch log group for FIS experiment logs
resource "aws_cloudwatch_log_group" "fis_logs" {
  name              = "/aws/fis/complete-example"
  retention_in_days = 7

  tags = {
    Environment = "test"
    Project     = "fis-complete-example"
  }
}

module "fis_experiment" {
  source = "../../"

  description = "Complete FIS experiment demonstrating all module features"
  name_prefix = "complete-fis"
  role_arn    = data.aws_iam_role.fis.arn

  # Multiple actions with dependencies
  actions = [
    {
      name        = "stop-instances"
      action_id   = "aws:ec2:stop-instances"
      description = "Stop EC2 instances to simulate instance failure"
      target      = "ec2-instances"
      parameters = {
        startInstancesAfterDuration = "PT5M"
      }
    },
    {
      name        = "wait-after-stop"
      action_id   = "aws:fis:wait"
      description = "Wait for 2 minutes after stopping instances"
      start_after = ["stop-instances"]
      parameters = {
        duration = "PT2M"
      }
    },
    {
      name        = "inject-cpu-stress"
      action_id   = "aws:ssm:send-command"
      description = "Inject CPU stress on target instances"
      target      = "ssm-instances"
      start_after = ["wait-after-stop"]
      parameters = {
        documentArn  = "arn:aws:ssm:us-east-1::document/AWSFIS-Run-CPU-Stress"
        documentParameters = "{\"DurationSeconds\":\"120\",\"InstallDependencies\":\"True\"}"
        duration     = "PT3M"
      }
    }
  ]

  # Multiple targets with different configurations
  targets = [
    {
      name           = "ec2-instances"
      resource_type  = "aws:ec2:instance"
      selection_mode = "COUNT(1)"
      resource_tags = {
        Environment = "test"
        FISTarget   = "true"
      }
    },
    {
      name           = "ssm-instances"
      resource_type  = "aws:ec2:instance"
      selection_mode = "PERCENT(50)"
      resource_tags = {
        Environment = "test"
        SSMEnabled  = "true"
      }
      filters = [
        {
          path   = "State.Name"
          values = ["running"]
        }
      ]
    }
  ]

  # Stop conditions with CloudWatch metric alarms
  stop_conditions = [
    {
      alarm_name          = "high-cpu"
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      statistic           = "Average"
      period              = 60
      threshold           = 90
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      alarm_description   = "Stop experiment if CPU exceeds 90%"
    },
    {
      alarm_name          = "high-error-rate"
      metric_name         = "5XXError"
      namespace           = "AWS/ApplicationELB"
      statistic           = "Sum"
      period              = 60
      threshold           = 100
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      alarm_description   = "Stop experiment if 5XX errors exceed threshold"
    }
  ]

  # S3 logging configuration
  s3_logging_configuration = {
    bucket_name = aws_s3_bucket.fis_logs.id
    prefix      = "fis-logs/"
  }

  # CloudWatch logging configuration
  cloudwatch_logging_configuration = {
    log_group_arn = aws_cloudwatch_log_group.fis_logs.arn
  }

  tags = {
    Environment = "test"
    Project     = "fis-complete-example"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "experiment_template_id" {
  description = "The ID of the FIS experiment template"
  value       = module.fis_experiment.experiment_template_id
}

output "experiment_template_arn" {
  description = "The ARN of the FIS experiment template"
  value       = module.fis_experiment.experiment_template_arn
}

output "cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm names to their ARNs (for stop conditions)"
  value       = module.fis_experiment.cloudwatch_alarm_arns
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket used for FIS experiment logs"
  value       = aws_s3_bucket.fis_logs.id
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group used for FIS experiment logs"
  value       = aws_cloudwatch_log_group.fis_logs.name
}
