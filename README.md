<!-- BEGIN_TF_DOCS -->
Module usage:

     module "fake\_elb" {
       source         = "git::https://github.com/UKHomeOffice/acp-tf-elb?ref=master"

       name                 = "my\_elb\_name"
       environment          = "dev"            # by default both Name and Env is added to the tags
       dns\_name             = "site"           # or defaults to var.name
       dns\_zone             = "example.com"
       proxy\_protocol       = true
       proxy\_protocol\_ports = ["80", "443"]
       vpc\_id               = "vpc-32323232"

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
           instance\_port     = "30100"
           lb\_port           = "80"
           instance\_protocol = "tcp"
           lb\_protocol       = "tcp"
         },
         {
           instance\_port     = "30101"
           lb\_port           = "443"
           instance\_protocol = "tcp"
           lb\_protocol       = "tcp"
         },
       ]

       tags            = {
         Role = "some\_tag"
       }
       # A series of tags applied to filter out the source subnets, by default Env and Role = elb-subnet is used
       subnet\_tags {
         Role = "some\_tag"
       }
     }

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.72.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_attachment.asg_attachment_bar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_elb.elb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elb) | resource |
| [aws_proxy_protocol_policy.proxy_protocol](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/proxy_protocol_policy) | resource |
| [aws_route53_record.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ipv6_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ipv6_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_autoscaling_groups.groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/autoscaling_groups) | data source |
| [aws_route53_zone.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnet_ids.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attach_elb"></a> [attach\_elb](#input\_attach\_elb) | Autoscaling group name used to find the autoscaling group to attach ELB | `string` | `""` | no |
| <a name="input_connection_draining"></a> [connection\_draining](#input\_connection\_draining) | Whether the ELB should drain connections | `bool` | `true` | no |
| <a name="input_connection_draining_timeout"></a> [connection\_draining\_timeout](#input\_connection\_draining\_timeout) | The timeout for draining connections from the ELB | `string` | `"120"` | no |
| <a name="input_cross_zone"></a> [cross\_zone](#input\_cross\_zone) | Should the ELB create be cross zone load balancing | `bool` | `true` | no |
| <a name="input_dns_name"></a> [dns\_name](#input\_dns\_name) | An optional hostname to add to the hosting zone, otherwise defaults to var.name | `string` | `""` | no |
| <a name="input_dns_type"></a> [dns\_type](#input\_dns\_type) | The dns record type to use when adding the dns entry | `string` | `"A"` | no |
| <a name="input_dns_zone"></a> [dns\_zone](#input\_dns\_zone) | The AWS route53 domain name hosting the dns entry, i.e. example.com | `any` | n/a | yes |
| <a name="input_egress"></a> [egress](#input\_egress) | A collection of maps which has port and optional protocol and cidr for egress rules | `list(map(string))` | <pre>[<br>  {<br>    "cidr": "0.0.0.0/0",<br>    "port": "-1",<br>    "protocol": "-1"<br>  }<br>]</pre> | no |
| <a name="input_elb_role_tag"></a> [elb\_role\_tag](#input\_elb\_role\_tag) | The role tag applied to the subnets used for ELB, i.e. Role = elb-subnet | `string` | `"elb-subnets"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | An environment name for the ELB, i.e. prod, dev, ci etc and used to search for assets | `any` | n/a | yes |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | The interval between health checks | `string` | `"30"` | no |
| <a name="input_health_check_port"></a> [health\_check\_port](#input\_health\_check\_port) | The node port we should use on the health check | `any` | n/a | yes |
| <a name="input_health_check_threshold"></a> [health\_check\_threshold](#input\_health\_check\_threshold) | The threshold for health checks marked healthy | `string` | `"2"` | no |
| <a name="input_health_check_timeout"></a> [health\_check\_timeout](#input\_health\_check\_timeout) | The timeout placed on the health checks | `string` | `"10"` | no |
| <a name="input_health_check_unhealthy"></a> [health\_check\_unhealthy](#input\_health\_check\_unhealthy) | The threshold of failed checks before marked unhealthy | `string` | `"3"` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | The timeout applie to idle ELB connections | `string` | `"120"` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | A collection of maps which has port and optional protocol and cidr for ingress rules | `list(map(string))` | n/a | yes |
| <a name="input_internal"></a> [internal](#input\_internal) | Indicates if the ELB should be an internal load balancer, defaults to true | `bool` | `true` | no |
| <a name="input_ipv6_egress"></a> [ipv6\_egress](#input\_ipv6\_egress) | A collection of maps which has port and optional protocol and cidr for ipv6 egress rules | `list(map(string))` | <pre>[<br>  {<br>    "cidr": "::/0",<br>    "port": "-1",<br>    "protocol": "-1"<br>  }<br>]</pre> | no |
| <a name="input_ipv6_ingress"></a> [ipv6\_ingress](#input\_ipv6\_ingress) | A collection of maps which has port and optional protocol and cidr for ipv6 ingress rules | `list(map(string))` | n/a | yes |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | A collection of elb listeners as defined by the provider | `list(map(string))` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | A descriptive name for this ELB | `any` | n/a | yes |
| <a name="input_proxy_protocol"></a> [proxy\_protocol](#input\_proxy\_protocol) | Indicates if proxy protocol should be enabled on node ports, defaults to false | `bool` | `false` | no |
| <a name="input_proxy_protocol_ports"></a> [proxy\_protocol\_ports](#input\_proxy\_protocol\_ports) | If enabled a list of lb ports which should use proxy protocol | `list(string)` | `[]` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | An optional list of security groups added to the created ELB | `list(string)` | `[]` | no |
| <a name="input_subnet_tags"></a> [subnet\_tags](#input\_subnet\_tags) | A map of tags used to filter the subnets you want the ELB attached | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags which will be added to the ELB cloud tags, by default Name, Env and KubernetesCluster is added | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC is we should build the ELB into | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns"></a> [dns](#output\_dns) | The FQDN of the newly created ELB |
| <a name="output_elb_dns_name"></a> [elb\_dns\_name](#output\_elb\_dns\_name) | The name given to the ELB just created |
| <a name="output_elb_id"></a> [elb\_id](#output\_elb\_id) | The ID for the ELB which has been created |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID for the security used to protected the ELB |
<!-- END_TF_DOCS -->