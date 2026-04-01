variable "ACCOUNT_ID" {
    type = string
}

variable "project_nick_name" {
    type = string
}

variable "project_name" {
    type = string
  
}
variable "domain" {
    type = string
}

variable "launch_templates" {
    type = map(object({
    id      = string
    name    = string
    version = number
  }))
}


variable "vpc_id" {
    type = string
  
}

variable "private_subnet_ids" {
    type = list(string)
  
}

variable "crm-internal-ecs-tg" {
    type = string
  
}
variable "crm-ecs-tg" {
    type = string

}
variable "payout-recon-task-role" {
    type = map(string)
  
}

variable "ecs-cluster-instance-profile" {
    type = map(string)
  
}
variable "ecs_task_role" {
    type = map(string)
  
}

variable "crm_service_sgroup_id" {
    type = string
  
}
variable "tasks_services_sgroup_id" {
    type = string
  
}
variable "redis_endpoint" {
    type = object({
    primary_endpoint_address = string
    reader_endpoint_address  = string
  })
  
}

variable "kms_key_id" {
    type = string
}

variable "db_enpoint" {
    type = string
}

variable "secret_manager" {
    type = object({
        username = string
        password = string
    })
}

variable "crm-service-role-arn" {
    type = string 
}

variable "crm-payin-internal-tg" {
    type = string
}

variable "crm-payin-tg" {
    type = string
}