output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "backend_url" {
  description = "URL of the backend application"
  value       = "http://${aws_lb.main.dns_name}/api"
}

output "jenkins_url" {
  description = "URL of the Jenkins server"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_eip.jenkins.public_ip
}

output "ecr_frontend_url" {
  description = "ECR URL for frontend image"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_url" {
  description = "ECR URL for backend image"
  value       = aws_ecr_repository.backend.repository_url
}