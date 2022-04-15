# 3 tier
Terraform code to setup 3 teir infrastructure.

Project consist of main.tf , variables.tf and terraform.tfvars files.

AWS services created by the script are VPC, private and public subnets, internet and NAT gateways, routetables and associations, ec2 instance and loadbalancer, S3 bucket and cloud front , mysql database instance.

Tier one has S3 bucket and cloud front for web layer.

Tier two has ec2 instance and loadbalancer for application layer.

Tier three has mysql rds database instance for database layer.

how to use

terraform init && terraform apply -var-file=terraform.tfvars
