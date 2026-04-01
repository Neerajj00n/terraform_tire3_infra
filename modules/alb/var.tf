variable "project_nick_name" {
    type = string
}

variable "project_name" {
    type = string
  
}
variable "domain" {
    type = string
}

variable "alb_cert" {
    type = string
}
variable "vpc_id" {
    type = string
  
}
variable "public_subnets" { 
  type = list(string)
}
variable "private_subnets" { 
  type = list(string)
}
variable "alb_security_group_id" {
    type = string
  
}