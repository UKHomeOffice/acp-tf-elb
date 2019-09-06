/**
 * Module usage:
 *
 *      module "fake_elb" {
 *        source         = "git::https://github.com/UKHomeOffice/acp-tf-elb?ref=master"
 *
 *        name                 = "my_elb_name"
 *        environment          = "dev"            # by default both Name and Env is added to the tags
 *        dns_name             = "site"           # or defaults to var.name
 *        dns_zone             = "example.com"
 *        proxy_protocol       = true
 *        proxy_protocol_ports = ["80", "443"]
 *        vpc_id               = "vpc-32323232"
 *
 *        ingress = [
 *          {
 *            "cidr"     = "0.0.0.0/0" # optional as it defaults
 *            "port"     = "80"
 *            "protocol" = "tcp" # optional as it default
 *          },
 *          {
 *            "port"     = "443"
 *            "protocol" = "tcp"
 *          },
 *        ]
 *
 *        # egress = []  same as above, defaults to a permit all
 *
 *        listeners = [
 *          {
 *            instance_port     = "30100"
 *            lb_port           = "80"
 *            instance_protocol = "tcp"
 *            lb_protocol       = "tcp"
 *          },
 *          {
 *            instance_port     = "30101"
 *            lb_port           = "443"
 *            instance_protocol = "tcp"
 *            lb_protocol       = "tcp"
 *          },
 *        ]
 *
 *        tags            = {
 *          Role = "some_tag"
 *        }
 *        # A series of tags applied to filter out the source subnets, by default Env and Role = elb-subnet is used
 *        subnet_tags {
 *          Role = "some_tag"
 *        }
 *      }
 *
 */
terraform {
  required_version = ">= 0.12"
}

# Get the VPC for this environment
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Get a list of ELB subnets
data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.selected.id
  tags   = var.subnet_tags
}

# Get the host zone id
data "aws_route53_zone" "selected" {
  name = "${var.dns_zone}."
}

## Security Group for the ELB
resource "aws_security_group" "sg" {
  name        = "${var.environment}-${var.name}-elb"
  description = "The security group for ELB on service: ${var.name}, environment: ${var.environment}"
  vpc_id      = data.aws_vpc.selected.id

  tags = merge(
    var.tags,
    {
      "Name" = format("%s-%s-elb", var.environment, var.name)
    },
    {
      "Env" = var.environment
    },
    {
      "KubernetesCluster" = var.environment
    },
  )
}

## Ingress Rules
resource "aws_security_group_rule" "ingress" {
  count = length(var.ingress)

  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  protocol          = lookup(var.ingress[count.index], "protocol", "tcp")
  from_port = lookup(
    var.ingress[count.index],
    "from_port",
    lookup(var.ingress[count.index], "port", ""),
  )
  to_port = lookup(
    var.ingress[count.index],
    "to_port",
    lookup(var.ingress[count.index], "port", ""),
  )
  cidr_blocks = [lookup(var.ingress[count.index], "cidr", "0.0.0.0/0")]
}

## Egress Rules
resource "aws_security_group_rule" "egress" {
  count = length(var.egress)

  type              = "egress"
  security_group_id = aws_security_group.sg.id
  protocol          = lookup(var.egress[count.index], "protocol", "tcp")
  from_port = lookup(
    var.egress[count.index],
    "from_port",
    lookup(var.egress[count.index], "port", ""),
  )
  to_port = lookup(
    var.egress[count.index],
    "to_port",
    lookup(var.egress[count.index], "port", ""),
  )
  cidr_blocks = [lookup(var.egress[count.index], "cidr", "0.0.0.0/0")]
}

## The ELB we are creating
resource "aws_elb" "elb" {
  name                        = "${var.environment}-${var.name}"
  connection_draining         = var.connection_draining
  connection_draining_timeout = var.connection_draining_timeout
  cross_zone_load_balancing   = var.cross_zone
  idle_timeout                = var.idle_timeout
  internal                    = var.internal
  dynamic "listener" {
    for_each = var.listeners
    content {
      instance_port     = listener.value.instance_port
      instance_protocol = listener.value.instance_protocol
      lb_port           = listener.value.lb_port
      lb_protocol       = listener.value.lb_protocol
    }
  }
  security_groups = concat(var.security_groups, [aws_security_group.sg.id])
  subnets         = data.aws_subnet_ids.selected.ids
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-%s", var.environment, var.name)
    },
    {
      "Env" = var.environment
    },
    {
      "KubernetesCluster" = var.environment
    },
  )

  health_check {
    healthy_threshold   = var.health_check_threshold
    unhealthy_threshold = var.health_check_unhealthy
    timeout             = var.health_check_timeout
    target              = "TCP:${var.health_check_port}"
    interval            = var.health_check_interval
  }
}

## Enable Proxy Protocol in the nodes ports if required
resource "aws_proxy_protocol_policy" "proxy_protocol" {
  count = var.proxy_protocol ? 1 : 0

  instance_ports = var.proxy_protocol_ports
  load_balancer  = aws_elb.elb.name
}

## Find autoscaling group to attach
data "aws_autoscaling_groups" "groups" {
  count = length(var.attach_elb) > 0 ? 1 : 0

  filter {
    name   = "key"
    values = ["Name"]
  }
  filter {
    name   = "value"
    values = [var.attach_elb] # this assumes "attach_elb" will not be a list, the count on this data object implies that it could be a list though
  }
}

### ELB Attachment is required
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  count = length(data.aws_autoscaling_groups.groups.*.names)

  # data.aws_autoscaling_groups.groups returns a map within a list because of count being used
  # e.g. [{names: [],values: []}] instead of {names: [],values: []}
  autoscaling_group_name = data.aws_autoscaling_groups.groups.0.names[count.index]
  elb                    = aws_elb.elb.id
}

## Create a DNS entry for this ELB
resource "aws_route53_record" "dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.dns_name == "" ? var.name : var.dns_name
  type    = var.dns_type

  alias {
    name                   = aws_elb.elb.dns_name
    zone_id                = aws_elb.elb.zone_id
    evaluate_target_health = true
  }
}
