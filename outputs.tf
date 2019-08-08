output "dns" {
  description = "The FQDN of the newly created ELB"
  value       = "${var.dns_name}.${var.dns_zone}"
}

output "elb_id" {
  description = "The ID for the ELB which has been created"
  value       = aws_elb.elb.id
}

output "elb_dns_name" {
  description = "The name given to the ELB just created"
  value       = aws_elb.elb.dns_name
}

output "security_group_id" {
  description = "The ID for the security used to protected the ELB"
  value       = aws_security_group.sg.id
}

