/**
 * Module usage:
 *
 *      module "github.com/UKHomeOffice/acp-tf-elb" {
 *        name            = "my_elb_name"
 *        environment     = "dev"            # by default both Name and Env is added to the tags
 *        dns_name        = "site"           # or defaults to var.name
 *        dns_zone        = "example.com"
 *        tags            = {
 *          Role = "some_tag"
 *        }
 *        cidr_access     = [ "1.0.0.1/32" ] # defaults to 0.0.0.0/0
 *        http_node_port  = "30204"
 *        https_node_port = "30205"
 *        proxy_protocol  = true
 *      }
 *
 */

# Get the VPC for this environment
data "aws_vpc" "selected" {
  tags {
    Env  = "${var.environment}"
  }
}

# Get a list of ELB subnets
data "aws_subnet_ids" "selected" {
  vpc_id = "${data.aws_vpc.selected.id}"
  tags {
    Env  = "${var.environment}"
    Role = "${var.elb_subnet_tag}"
  }
}

# Get the host zone id
data "aws_route53_zone" "selected" {
  name         = "${var.dns_zone}."
  private_zone = false
}

## Security Group for the ELB
resource "aws_security_group" "sg" {
  name        = "${var.environment}-${var.name}-elb"
  description = "The security group for ELB on service: ${var.name}, environment: ${var.environment}"
  vpc_id      = "${data.aws_vpc.selected.id}"

  tags = "${merge(var.tags, map("Name", format("%s", var.name)), map("Env", format("%s", var.environment)))}"
}

# Ingress HTTP Port
resource "aws_security_group_rule" "in_http" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.sg.id}"
  protocol                 = "tcp"
  from_port                = "${var.http_port}"
  to_port                  = "${var.http_port}"
  cidr_blocks              = [ "${var.cidr_access}" ]
}

# Ingress HTTPS Port
resource "aws_security_group_rule" "in_https" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.sg.id}"
  protocol                 = "tcp"
  from_port                = "${var.https_port}"
  to_port                  = "${var.https_port}"
  cidr_blocks              = [ "${var.cidr_access}" ]
}

## Engress Rules HTTP Node Port
resource "aws_security_group_rule" "out_http" {
  type                     = "egress"
  security_group_id        = "${aws_security_group.sg.id}"
  protocol                 = "tcp"
  from_port                = "${var.http_node_port}"
  to_port                  = "${var.http_node_port}"
  cidr_blocks              = [ "0.0.0.0/0" ]
}

## Engress Rules HTTPS Node Port
resource "aws_security_group_rule" "out_https" {
  type                     = "egress"
  security_group_id        = "${aws_security_group.sg.id}"
  protocol                 = "tcp"
  from_port                = "${var.https_node_port}"
  to_port                  = "${var.https_node_port}"
  cidr_blocks              = [ "0.0.0.0/0" ]
}

# The ELB we are creating
resource "aws_elb" "elb" {
  name            = "${var.name}"
  internal        = "${var.internal}"
  subnets         = [ "${length(var.subnets) > 0 ? var.subnets : data.aws_subnet_ids.selected.ids}" ]
  security_groups = [ "${aws_security_group.sg.id}" ]

  listener {
    instance_port       = "${var.http_node_port}"
    instance_protocol   = "tcp"
    lb_port             = "${var.http_port}"
    lb_protocol         = "tcp"
  }

  listener {
    instance_port       = "${var.https_node_port}"
    instance_protocol   = "tcp"
    lb_port             = "${var.https_port}"
    lb_protocol         = "tcp"
  }

  health_check {
    healthy_threshold   = "${var.health_check_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
    timeout             = "${var.health_check_timeout}"
    target              = "TCP:${var.health_check_port}"
    interval            = "${var.health_check_interval}"
  }

  connection_draining         = "${var.connection_draining}"
  connection_draining_timeout = "${var.connection_draining_timeout}"
  cross_zone_load_balancing   = "${var.cross_zone}"
  idle_timeout                = "${var.idle_timeout}"

  tags = "${merge(var.tags, map("Name", format("%s", var.name)), map("Env", format("%s", var.environment)))}"
}

# Enable Proxy Protocol in the nodes ports if required
resource "aws_proxy_protocol_policy" "proxy_protocol" {
  count          = "${var.proxy_protocol ? 1 : 0}"
  load_balancer  = "${aws_elb.elb.name}"
  instance_ports = [ "${var.http_node_port}", "${var.https_node_port}" ]
}

## Create a DNS entry for this ELB
resource "aws_route53_record" "dns" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.dns_name == "" ? var.name : var.dns_name}"
  type    = "A"

  alias {
    name                   = "${aws_elb.elb.dns_name}"
    zone_id                = "${aws_elb.elb.zone_id}"
    evaluate_target_health = true
  }
}
