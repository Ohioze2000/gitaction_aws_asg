#
variable "env_prefix"{
  type = string
  description = "ENVIRONMENT PREFIX"
}

variable "vpc_id" {
  description = "The ID of the VPC where the ALB will be deployed."
  type        = string # Added type declaration
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the ALB will be deployed."
  type        = list(string)
}

# variable "instance_ids" {
#   description = "List of EC2 instance IDs to attach to the ALB target group"
#   type        = list(string)
# }

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the HTTPS listener."
  type        = string
}