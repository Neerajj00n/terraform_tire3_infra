terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-south-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}


locals {
  ecr_repositories = toset([
    "crm-ecr",
    "payout-refund-worker",
    "webhook-worker",
    "payout-status-enquiry-worker",
  ])
}

module "iam" {
  source = "./modules/iam"
  project_nick_name = var.project_nick_name
  ACCOUNT_ID = var.ACCOUNT_ID
  domain = var.domain
  kms_key_id = aws_kms_key.KMSKey.key_id
  cfd_frontend_arn = module.cloudfront.cfd_frontend_arn
  cfd_onboarding_arn = module.cloudfront.cfd_onboarding_arn
  s3 = {
    crm-service = module.s3.crm-service-bucket
    logs = module.s3.logs-bucket
    crm-frontend = module.s3.crm-frontend-bucket
    download-center = module.s3.download-center-bucket
    onboarding      = module.s3.onboarding-bucket  


  }
}
module "vpc" {
  source = "./modules/vpc"
  project_name = var.project_name
  project_nick_name = var.project_nick_name
  azs = var.azs
  domain = var.domain
  ACCOUNT_ID = var.ACCOUNT_ID

}

module "alb" {
  source = "./modules/alb"
  domain =  var.domain
  project_name = var.project_name
  project_nick_name = var.project_nick_name
  alb_cert = module.route53.alb_cert.arn
  public_subnets = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id
  alb_security_group_id = module.securitygroup.alb_security_group_id

}

module "route53" {
  source = "./modules/route53"
    providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  domain = var.domain
  ACCOUNT_ID = var.ACCOUNT_ID
  project_name = var.project_name
  project_nick_name = var.project_nick_name
  vpc_id = module.vpc.vpc_id
  cfd_frontend_domain_name = module.cloudfront.cfd_frontend_domain_name
  cfd_onboarding_domain_name = module.cloudfront.cfd_onboarding_domain_name
  ecs_internal_alb_dns_name = module.alb.alb_internal_dns
  ecs_alb_dns_name = module.alb.alb_dns
}

module "cloudfront" {
  source = "./modules/cloudfront"
  domain = var.domain
  cloudfront_cert = module.route53.cloudfront_cert.arn
  public_subnets = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  ACCOUNT_ID = var.ACCOUNT_ID
  project_nick_name = var.project_nick_name
  project_name = var.project_name
}

module "securitygroup" {
  source = "./modules/securitygroup"
  vpc_id = module.vpc.vpc_id
}

module "rds" {
  source = "./modules/rds"
  project_nick_name = var.project_nick_name
  project_name = var.project_name
  private_subnets = module.vpc.private_subnets
  redis_sg_id = module.securitygroup.redis_sg_id
  rds_sg_id = module.securitygroup.rds_sg_id
  dbpassword = var.dbpassword
}

module "ecs" {
  source = "./modules/ecs"
  vpc_id = module.vpc.vpc_id
  domain = var.domain
  private_subnet_ids = module.vpc.private_subnets
  ACCOUNT_ID = var.ACCOUNT_ID
  project_nick_name = var.project_nick_name
  project_name = var.project_name
  payout-recon-task-role = module.iam.payout-recon-task-role
  crm-internal-ecs-tg = module.alb.crm-internal-ecs-tg
  crm-ecs-tg = module.alb.crm-ecs-tg
  ecs-cluster-instance-profile = module.iam.ecs-cluster-instance-profile
  ecs_task_role = module.iam.ecs_task_role
  launch_templates = module.ec2.launch_templates
  crm_service_sgroup_id = module.securitygroup.crm_service_sgroup_id
  tasks_services_sgroup_id = module.securitygroup.tasks_services_sgroup_id
  kms_key_id = aws_kms_key.KMSKey.key_id
  redis_endpoint = module.rds.redis_enpoint
  db_enpoint = module.rds.rds_endpoint
  crm-service-role-arn = module.iam.crm-service-role.arn
  crm-payin-tg = module.alb.crm-payin-tg
  crm-payin-internal-tg = module.alb.crm-payin-internal-tg
  secret_manager = {
    username = aws_secretsmanager_secret.username.arn
    password = aws_secretsmanager_secret.password.arn
  }
}


module "ec2" {
  source = "./modules/ec2"
  main_cluster_name = module.ecs.main_cluster_name
  task_cluster_name = module.ecs.task_cluster_name
  logs_bucket = module.s3.logs-bucket
  ecs-cluster-instance-profile = module.iam.ecs-cluster-instance-profile.arn
  ecs_security_group = module.securitygroup.ecs_security_group_id
}

module "s3" {
  source = "./modules/s3"
  project_nick_name = var.project_nick_name
  domain = var.domain

}

####################################################################
resource "aws_ecr_repository" "this" {
  for_each = local.ecr_repositories
  name     = each.value
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = local.ecr_repositories
  repository = each.value

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "untagged"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}


######################SQS############################

variable "sqs_queues" {
  type = map(object({
    name                       = string
    message_retention_seconds  = number
    receive_wait_time_seconds  = number
    visibility_timeout_seconds = number
  }))
  default = {
    payout_long_running = {
      name                       = "payout-long-running-status-enquiry-worker-queue"
      message_retention_seconds = 1800
      receive_wait_time_seconds = 20
      visibility_timeout_seconds = 150
    }

    payout_refund = {
      name                       = "payout-refund-worker-queue"
      message_retention_seconds = 14400
      receive_wait_time_seconds = 0
      visibility_timeout_seconds = 30
    }

    settlement = {
      name                       = "settlement-queue"
      message_retention_seconds = 345600
      receive_wait_time_seconds = 0
      visibility_timeout_seconds = 30
    }

    webhook = {
      name                       = "webhook-worker-queue"
      message_retention_seconds = 14400
      receive_wait_time_seconds = 10
      visibility_timeout_seconds = 30
    }

    payin_webhook = {
      name                       = "payin-webhook-worker-queue"
      message_retention_seconds = 14400
      receive_wait_time_seconds = 10
      visibility_timeout_seconds = 30
    }
  }
}
resource "aws_sqs_queue" "queues" {
  for_each = var.sqs_queues

  name                       = each.value.name
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = each.value.message_retention_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
}


#################################################################
#secretManger
resource "aws_secretsmanager_secret" "username" {
        name = "production/db/credentials/username"
        tags = {
            Environment = "production"
        }
    }
resource "aws_secretsmanager_secret_version" "usernamestore" {
    secret_id = aws_secretsmanager_secret.username.id
    secret_string = "${var.project_name}_user"
}

resource "aws_secretsmanager_secret" "password" {
    name = "production/db/credentials/password"
    tags = {
        Environment = "production"
    }
}

resource "aws_secretsmanager_secret_version" "passwordstore" {
    secret_id = aws_secretsmanager_secret.password.id
    secret_string = var.dbpassword
}


# KMS
resource "aws_kms_key" "KMSKey" {
    is_enabled = true
    description = "Salt Encryption Key"
    key_usage = "ENCRYPT_DECRYPT"
    policy = <<EOF
{
  "Version" : "2012-10-17",
  "Id" : "key-default-1",
  "Statement" : [ {
    "Sid" : "Enable IAM User Permissions",
    "Effect" : "Allow",
    "Principal" : {
      "AWS" : "arn:aws:iam::${var.ACCOUNT_ID}:root"
    },
    "Action" : "kms:*",
    "Resource" : "*"
  } ]
}
EOF
}
