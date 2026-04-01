variable "ACCOUNT_ID" {
    type = string
  
}
variable "domain" {
    type = string
}

variable "project_nick_name" {
    type = string
  
}
variable "kms_key_id" {
    type = string
  
}

variable "s3" {
  type = map(string)
}

variable "cfd_frontend_arn" {
    type = string
}

variable "cfd_onboarding_arn" {
    type = string
}