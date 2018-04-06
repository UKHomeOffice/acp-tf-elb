variable "name" {
  description = "A descriptive name for this ELB"
}

variable "environment" {
  description = "An envionment name for the ELB, i.e. prod, dev, ci etc and used to search for assets"
}

variable "dns_zone" {
  description = "The AWS route53 domain name hosting the dns entry, i.e. example.com"
}

variable "listeners" {
  description = "A collection of maps which has port, node_port, protocol and cidr"
  type        = "list"
}

variable "attach_elb" {
  description = "Autoscaling group name used to find the autoscaling group to attach ELB"
  default     = ""
}

variable "health_check_port" {
  description = "The node port we should use on the health check"
}

variable "dns_name" {
  description = "An optional hostname to add to the hosting zone, otherwise defaults to var.name"
  default     = ""
}

variable "dns_type" {
  description = "The dns record type to use when adding the dns entry"
  default     = "A"
}

variable "elb_role_tag" {
  description = "The role tag applied to the subnets used for ELB, i.e. Role = elb-subnet"
  default     = "elb-subnets"
}

variable "subnet_tags" {
  description = "A map of tags used to filter the subnets you want the ELB attached"
  default     = {}
}

variable "proxy_protocol" {
  description = "Indicates if proxy protocol should be enabled on node ports, defaults to false"
  default     = false
}

variable "security_groups" {
  description = "An optional list of security groups added to the created ELB"
  default     = []
}

variable "tags" {
  description = "A map of tags which will be added to the ELB cloud tags, by default Name, Env and KubernetesCluster is added"
  default     = {}
}

variable "internal" {
  description = "Indicates if the ELB should be an internal load balancer, defaults to true"
  default     = true
}

variable "connection_draining" {
  description = "Whether the ELB should drain connections"
  default     = true
}

variable "connection_draining_timeout" {
  description = "The timeout for draining connections from the ELB"
  default     = "120"
}

variable "cross_zone" {
  description = "Should the ELB create be cross zone load balancing"
  default     = true
}

variable "idle_timeout" {
  description = "The timeout applie to idle ELB connections"
  default     = "120"
}

variable "health_check_interval" {
  description = "The interval between health checks"
  default     = "30"
}

variable "health_check_threshold" {
  description = "The threshold for health checks marked healthy"
  default     = "2"
}

variable "health_check_unhealthy" {
  description = "The threshold of failed checks before marked unhealthy"
  default     = "3"
}

variable "health_check_timeout" {
  description = "The timeout placed on the health checks"
  default     = "10"
}

variable "vpc_id" {
  description = "The VPC ID to create the resources within"
}
