/**
 * Module usage:
 *
 *      module "fake_elb" {
 *        source         = "git::https://github.com/UKHomeOffice/acp-tf-elb?ref=master"
 *
 *        name            = "my_elb_name"
 *        environment     = "dev"            # by default both Name and Env is added to the tags
 *        dns_name        = "site"           # or defaults to var.name
 *        dns_zone        = "example.com"
 *        tags            = {
 *          Role = "some_tag"
 *        }
 *        # A series of tags applied to filter out the source subnets, by default Env and Role = elb-subnet is used
 *        subnet_tags {
 *          Role = "some_tag"
 *        }
 *        cidr_access     = [ "1.0.0.1/32" ] # defaults to 0.0.0.0/0
 *        http_node_port  = "30204"
 *        https_node_port = "30205"
 *        proxy_protocol  = true
 *      }
 *
 */

# Get a list of ELB subnets
data "aws_subnet_ids" "selected" {
  vpc_id = "${var.vpc_id}"
  tags   = "${var.subnet_tags}"
}

# Get the host zone id
data "aws_route53_zone" "selected" {
  name = "${var.dns_zone}."
}

## Security Group for the ELB)
resource "aws_security_group" "sg" {
  name        = "${var.environment}-${var.name}-elb"
  description = "The security group for ELB on service: ${var.name}, environment: ${var.environment}"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(var.tags, map("Name", format("%s-%s-elb", var.environment, var.name)), map("Env", var.environment), map("KubernetesCluster", var.environment))}"
}

# Ingress HTTP Port
resource "aws_security_group_rule" "in_http" {
  type              = "ingress"
  security_group_id = "${aws_security_group.sg.id}"
  protocol          = "tcp"
  from_port         = "${var.http_port}"
  to_port           = "${var.http_port}"
  cidr_blocks       = ["${var.cidr_access}"]
}

# Ingress HTTPS Port
resource "aws_security_group_rule" "in_https" {
  type              = "ingress"
  security_group_id = "${aws_security_group.sg.id}"
  protocol          = "tcp"
  from_port         = "${var.https_port}"
  to_port           = "${var.https_port}"
  cidr_blocks       = ["${var.cidr_access}"]
}

## Engress Rules HTTP Node Port
resource "aws_security_group_rule" "out_http" {
  type              = "egress"
  security_group_id = "${aws_security_group.sg.id}"
  protocol          = "tcp"
  from_port         = "${var.http_node_port}"
  to_port           = "${var.http_node_port}"
  cidr_blocks       = ["0.0.0.0/0"]
}

## Engress Rules HTTPS Node Port
resource "aws_security_group_rule" "out_https" {
  type              = "egress"
  security_group_id = "${aws_security_group.sg.id}"
  protocol          = "tcp"
  from_port         = "${var.https_node_port}"
  to_port           = "${var.https_node_port}"
  cidr_blocks       = ["0.0.0.0/0"]
}

## The ELB we are creating
resource "aws_elb" "elb" {
  name            = "${var.environment}-${var.name}"
  internal        = "${var.internal}"
  subnets         = ["${data.aws_subnet_ids.selected.ids}"]
  security_groups = ["${aws_security_group.sg.id}"]

  listener {
    instance_port     = "${var.http_node_port}"
    instance_protocol = "tcp"
    lb_port           = "${var.http_port}"
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = "${var.https_node_port}"
    instance_protocol = "tcp"
    lb_port           = "${var.https_port}"
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = "${var.health_check_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
    timeout             = "${var.health_check_timeout}"
    target              = "TCP:${var.health_check_port == "" ? var.https_node_port : var.health_check_port}"
    interval            = "${var.health_check_interval}"
  }

  connection_draining         = "${var.connection_draining}"
  connection_draining_timeout = "${var.connection_draining_timeout}"
  cross_zone_load_balancing   = "${var.cross_zone}"
  idle_timeout                = "${var.idle_timeout}"

  tags = "${merge(var.tags, map("Name", format("%s-%s", var.environment, var.name)), map("Env", var.environment), map("KubernetesCluster", var.environment))}"
}

## Enable Proxy Protocol in the nodes ports if required
resource "aws_proxy_protocol_policy" "proxy_protocol" {
  count          = "${var.proxy_protocol ? 1 : 0}"
  load_balancer  = "${aws_elb.elb.name}"
  instance_ports = ["${var.http_node_port}", "${var.https_node_port}"]
}

## Find autoscaling group to attach
data "aws_autoscaling_groups" "groups" {
  count = "${length(var.attach_elb) > 0 ? 1 : 0}"

  filter = [
    {
      name   = "key"
      values = ["Name"]
    },
    {
      name   = "value"
      values = ["${var.attach_elb}"]
    },
  ]
}

### ELB Attachment is required
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  count = "${length(data.aws_autoscaling_groups.groups.*.names)}"

  autoscaling_group_name = "${data.aws_autoscaling_groups.groups.names[count.index]}"
  elb                    = "${aws_elb.elb.id}"
}

## Create a DNS entry for this ELB
resource "aws_route53_record" "dns" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.dns_name == "" ? var.name : var.dns_name}"
  type    = "${var.dns_type}"

  alias {
    name                   = "${aws_elb.elb.dns_name}"
    zone_id                = "${aws_elb.elb.zone_id}"
    evaluate_target_health = true
  }
}
