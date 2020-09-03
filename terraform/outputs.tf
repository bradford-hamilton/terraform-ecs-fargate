# outputs.tf

output "alb_hostname" {
  value = aws_alb.bluegreen-alb.dns_name
}

