output "load_test_instance_id" {
  description = "EC2 instance ID for load testing"
  value       = aws_instance.load_test.id
}

output "load_test_public_ip" {
  description = "Public IP address of the load test EC2 instance"
  value       = aws_instance.load_test.public_ip
}

output "load_test_ssh_command" {
  description = "SSH command to connect to the load test instance"
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.load_test.public_ip}"
}

output "target_base_url_effective" {
  description = "Effective target URL used by k6 (manual value or deployment state output)"
  value       = local.target_base_url_effective
}
