# Module output definitions

output "experiment_template_id" {
  description = "The ID of the FIS experiment template"
  value       = aws_fis_experiment_template.this.id
}

output "experiment_template_arn" {
  description = "The ARN of the FIS experiment template"
  value       = aws_fis_experiment_template.this.arn
}

output "cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm names to their ARNs (for stop conditions)"
  value       = { for k, v in aws_cloudwatch_metric_alarm.stop_condition : k => v.arn }
}
