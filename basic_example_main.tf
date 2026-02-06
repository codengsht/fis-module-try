# Basic FIS Experiment Template Example
#
# This example demonstrates the minimum required configuration for the FIS module.
# It creates a simple experiment that stops EC2 instances tagged with Environment=test.

provider "aws" {
  region = "us-east-1"
}

module "fis_experiment" {
  source = "../../"

  description = "Basic FIS experiment to stop EC2 instances"
  name_prefix = "basic-fis"

  actions = [
    {
      name      = "stop-instances"
      action_id = "aws:ec2:stop-instances"
      target    = "ec2-instances"
    }
  ]

  targets = [
    {
      name           = "ec2-instances"
      resource_type  = "aws:ec2:instance"
      selection_mode = "ALL"
      resource_tags = {
        Environment = "test"
      }
    }
  ]

  tags = {
    Environment = "test"
    Project     = "fis-basic-example"
  }
}

output "experiment_template_id" {
  description = "The ID of the FIS experiment template"
  value       = module.fis_experiment.experiment_template_id
}

output "experiment_template_arn" {
  description = "The ARN of the FIS experiment template"
  value       = module.fis_experiment.experiment_template_arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role used by the FIS experiment"
  value       = module.fis_experiment.iam_role_arn
}
