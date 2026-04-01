variable "project_nick_name" {
    type = string
}

variable "project_name" {
    type = string
  
}

variable "private_subnets" {
    type = list(string)  
}

variable "redis_sg_id" {
    type = string
  
}

variable "rds_sg_id" {
    type = string
}
variable "dbpassword" {
    type = string
  
}