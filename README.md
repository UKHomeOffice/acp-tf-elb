Module usage:

     module "fake_elb" {
       source         = "git::https://github.com/UKHomeOffice/acp-tf-elb?ref=master"

       name                 = "my_elb_name"
       environment          = "dev"            # by default both Name and Env is added to the tags
       dns_name             = "site"           # or defaults to var.name
       dns_zone             = "example.com"
       proxy_protocol       = true
       proxy_protocol_ports = ["80", "443"]
       vpc_id               = "vpc-32323232"

       ingress = [
         {
           "cidr"     = "0.0.0.0/0" # optional as it defaults
           "port"     = "80"
           "protocol" = "tcp" # optional as it default
         },
         {
           "port"     = "443"
           "protocol" = "tcp"
         },
       ]

       # egress = []  same as above, defaults to a permit all

       listeners = [
         {
           instance_port     = "30100"
           lb_port           = "80"
           instance_protocol = "tcp"
           lb_protocol       = "tcp"
         },
         {
           instance_port     = "30101"
           lb_port           = "443"
           instance_protocol = "tcp"
           lb_protocol       = "tcp"
         },
       ]

       tags            = {
         Role = "some_tag"
       }
       # A series of tags applied to filter out the source subnets, by default Env and Role = elb-subnet is used
       subnet_tags {
         Role = "some_tag"
       }
     }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| attach_elb | Autoscaling group name used to find the autoscaling group to attach ELB | `` | no |
| connection_draining | Whether the ELB should drain connections | `true` | no |
| connection_draining_timeout | The timeout for draining connections from the ELB | `120` | no |
| cross_zone | Should the ELB create be cross zone load balancing | `true` | no |
| dns_name | An optional hostname to add to the hosting zone, otherwise defaults to var.name | `` | no |
| dns_type | The dns record type to use when adding the dns entry | `A` | no |
| dns_zone | The AWS route53 domain name hosting the dns entry, i.e. example.com | - | yes |
| egress | A collection of maps which has port and optional protocol and cidr for egress rules | `<list>` | no |
| ipv6_egress | A collection of maps which has port and optional protocol and cidr for ipv6 egress rules | `<list>` | no |
| elb_role_tag | The role tag applied to the subnets used for ELB, i.e. Role = elb-subnet | `elb-subnets` | no |
| environment | An environment name for the ELB, i.e. prod, dev, ci etc and used to search for assets | - | yes |
| health_check_interval | The interval between health checks | `30` | no |
| health_check_port | The node port we should use on the health check | - | yes |
| health_check_threshold | The threshold for health checks marked healthy | `2` | no |
| health_check_timeout | The timeout placed on the health checks | `10` | no |
| health_check_unhealthy | The threshold of failed checks before marked unhealthy | `3` | no |
| idle_timeout | The timeout applie to idle ELB connections | `120` | no |
| ingress | A collection of maps which has port and optional protocol and cidr for ingress rules | - | yes |
| ipv6_ingress | A collection of maps which has port and optional protocol and cidr for ipv6 ingress rules | - | yes |
| internal | Indicates if the ELB should be an internal load balancer, defaults to true | `true` | no |
| listeners | A collection of elb listeners as defined by the provider | - | yes |
| name | A descriptive name for this ELB | - | yes |
| proxy_protocol | Indicates if proxy protocol should be enabled on node ports, defaults to false | `false` | no |
| proxy_protocol_ports | If enabled a list of lb ports which should use proxy protocol | `<list>` | no |
| security_groups | An optional list of security groups added to the created ELB | `<list>` | no |
| subnet_tags | A map of tags used to filter the subnets you want the ELB attached | `<map>` | no |
| tags | A map of tags which will be added to the ELB cloud tags, by default Name, Env and KubernetesCluster is added | `<map>` | no |
| vpc_id | The VPC is we should build the ELB into | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| dns |  |
| elb_dns_name |  |
| elb_id |  |
| security_group_id |  |

