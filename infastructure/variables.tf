variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "devops-challenge"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "frontend_port" {
  description = "Port for frontend container"
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "Port for backend container"
  type        = number
  default     = 8080
}

variable "frontend_image" {
  description = "ECR image URI for frontend"
  type        = string
  default     = ""
}

variable "backend_image" {
  description = "ECR image URI for backend"
  type        = string
  default     = ""
}

variable "frontend_cpu" {
  description = "CPU units for frontend task"
  type        = number
  default     = 512
}

variable "frontend_memory" {
  description = "Memory for frontend task in MB"
  type        = number
  default     = 1024
}

variable "backend_cpu" {
  description = "CPU units for backend task"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory for backend task in MB"
  type        = number
  default     = 1024
}

variable "min_tasks" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "desired_tasks" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "max_tasks" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 4
}

variable "cpu_threshold" {
  description = "CPU utilization % to trigger auto scaling"
  type        = number
  default     = 50
}

variable "key_name" {
  description = "EC2 key pair name for Jenkins"
  type        = string
  default     = "techchallenge"
}