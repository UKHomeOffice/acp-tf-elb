Module usage:

     module "fake_elb"" {
       source         = "git::https://github.com/UKHomeOffice/acp-tf-elb?ref=master"

       name            = "my_elb_name"
       environment     = "dev"            # by default both Name and Env is added to the tags
       vpc_id          = "${module.infra.vpc_id}"
       dns_name        = "site"           # or defaults to var.name
       dns_zone        = "example.com"
       tags            = {
         Role = "some_tag"
       }
       # A series of tags applied to filter out the source subnets, by default Env and Role = elb-subnet is used
       subnet_tags {
         Role = "some_tag"
       }
       cidr_access     = [ "1.0.0.1/32" ] # defaults to 0.0.0.0/0
       http_node_port  = "30204"
       https_node_port = "30205"
       proxy_protocol  = true
     }



## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cidr_access | A collection of network CIDR able to access this ELB, defaults to all | string | `<list>` | no |
| connection_draining | Whether the ELB should drain connections | string | `true` | no |
| connection_draining_timeout | The timeout for draining connections from the ELB | string | `120` | no |
| cross_zone | Should the ELB create be cross zone load balancing | string | `true` | no |
| dns_name | An optional hostname to add to the hosting zone, otherwise defaults to var.name | string | `` | no |
| dns_type | The dns record type to use when adding the dns entry | string | `A` | no |
| dns_zone | The AWS route53 domain name hosting the dns entry, i.e. example.com | string | - | yes |
| elb_role_tag | The role tag applied to the subnets used for ELB, i.e. Role = elb-subnet | string | `elb-subnets` | no |
| environment | An envionment name for the ELB, i.e. prod, dev, ci etc and used to search for assets | string | - | yes |
| health_check_interval | The interval between health checks | string | `30` | no |
| health_check_port | The node port we should use on the health check, defaults to var.https_node_port | string | `` | no |
| health_check_threshold | The threshold for health checks marked healthy | string | `2` | no |
| health_check_timeout | The timeout placed on the health checks | string | `10` | no |
| health_check_unhealthy | The threshold of failed checks before marked unhealthy | string | `3` | no |
| http_node_port | The http node port the ELB should be forwarding to | string | - | yes |
| http_port | The ingress port running http | string | `80` | no |
| https_node_port | The https node port the ELB should be forwarding to | string | - | yes |
| https_port | the ingress port which is running https | string | `443` | no |
| idle_timeout | The timeout applie to idle ELB connections | string | `120` | no |
| internal | Indicates if the ELB should be an internal load balancer, defaults to true | string | `true` | no |
| name | A descriptive name for this ELB | string | - | yes |
| proxy_protocol | Indicates if proxy protocol should be enabled on node ports, defaults to false | string | `false` | no |
| security_groups | An optional list of security groups added to the created ELB | string | `<list>` | no |
| subnet_tags | A map of tags used to filter the subnets you want the ELB attached | string | `<map>` | no |
| tags | A map of tags which will be added to the ELB cloud tags, by default Name, Env and KubernetesCluster is added | string | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| dns | The FQDN of the newly created ELB |
| elb_dns_name | The name given to the ELB just created |
| elb_id | The ID for the ELB which has been created |
| security_group_id | The ID for the security used to protected the ELB |

