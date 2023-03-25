# ------------------------------------------------------------
# Define global environments
# ------------------------------------------------------------
variable "environment" {
  type        = string
  description = "Environment name or equivalent for CI CD and resource naming purpose."
}

variable "account_id" {
  type        = string
  description = "The ID that belongs to the Account."
}

variable "region" {
  type        = string
  description = "Region where resources are deployed in."
}

variable "project" {
  type        = string
  description = "The name of the project."
}

# ------------------------------------------------------------
# S3 Selfie Alert
# ------------------------------------------------------------
variable "webhook_url" {
  type        = string
  description = "webhook url"
}