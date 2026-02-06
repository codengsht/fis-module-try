# Input variable definitions with validation

variable "description" {
  description = "Description of the FIS experiment template"
  type        = string
  default     = "FIS Experiment Template"
}

variable "name_prefix" {
  description = "Prefix for naming resources (IAM role, alarms)"
  type        = string
  default     = "fis"
}

variable "tags" {
  description = "Tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}

variable "actions" {
  description = "List of FIS actions to perform during the experiment"
  type = list(object({
    name        = string
    action_id   = string
    description = optional(string)
    parameters  = optional(map(string))
    target      = optional(string)
    start_after = optional(list(string))
  }))

  validation {
    condition     = length(var.actions) > 0
    error_message = "At least one action must be provided."
  }
}

variable "targets" {
  description = "List of targets for FIS actions"
  type = list(object({
    name           = string
    resource_type  = string
    selection_mode = string
    resource_arns  = optional(list(string))
    resource_tags  = optional(map(string))
    filters = optional(list(object({
      path   = string
      values = list(string)
    })))
  }))

  validation {
    condition     = length(var.targets) > 0
    error_message = "At least one target must be provided."
  }
}

variable "stop_conditions" {
  description = "List of CloudWatch metric alarm configurations for stop conditions"
  type = list(object({
    alarm_name          = string
    metric_name         = string
    namespace           = string
    statistic           = string
    period              = number
    threshold           = number
    comparison_operator = string
    evaluation_periods  = optional(number, 1)
    dimensions          = optional(map(string))
    alarm_description   = optional(string)
  }))
  default = []
}

variable "s3_logging_configuration" {
  description = "S3 logging configuration for FIS experiment logs"
  type = object({
    bucket_name = string
    prefix      = optional(string, "")
  })
  default = null
}

variable "cloudwatch_logging_configuration" {
  description = "CloudWatch Logs configuration for FIS experiment logs"
  type = object({
    log_group_arn = string
  })
  default = null

  validation {
    condition = var.cloudwatch_logging_configuration == null || can(regex(
      "^arn:aws:logs:[a-z0-9-]+:[0-9]+:log-group:.+$",
      var.cloudwatch_logging_configuration.log_group_arn
    ))
    error_message = "The log_group_arn must be a valid CloudWatch Log Group ARN."
  }
}
