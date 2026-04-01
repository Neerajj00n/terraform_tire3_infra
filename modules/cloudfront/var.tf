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

variable "cloudfront_cert" { 
    type = string
}

variable "public_subnets" { 
  type = list(string)
}
variable "private_subnets" { 
  type = list(string)
}