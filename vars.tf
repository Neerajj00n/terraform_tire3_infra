variable "project_name" {
    type = string
  
}
variable "domain" {
    description = "domain name product"
    type = string
  
}
variable "project_nick_name" {
    type = string
  
}
variable ACCOUNT_ID {
  type = string

}
variable "azs" {
 type        = list(string)
 description = "Availability Zones"
}
variable "dbpassword" {
    type = string
  
}















# variable instance_role {
#   default = "ec2-instence-role"
# }

# variable ami {
#   type = string
#   default = "ami-0d2986f2e8c0f7d01"
# }

# variable "bucket_name" {
#   description = "name of the s3 bucket. Must be unique."
#   type        = string
#   default     = "crm-service"
# }

# variable VPC {
#   default = "vpc-04f471493d1fd984f"
# }



# variable "public_subnet_cidrs" {
#  type        = list(string)
#  description = "Public Subnet CIDR values"
#  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
# }
 
# variable "private_subnet_cidrs" {
#  type        = list(string)
#  description = "Private Subnet CIDR values"
#  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
# }

# variable "public_subnet_ids" {
#  type        = list(string)
#  description = "Public Subnet CIDR values"
#  default     = ["subnet-022ff3a97a52f3d98", "subnet-0cd71f9c4e74d538b", "subnet-04c578c34baad6892"]
# }

# variable "private_subnet_ids" {
#  type        = list(string)
#  description = "Private Subnet CIDR values"
#  default     = ["subnet-04f701bfa932ace2c", "subnet-047503fbc84408d68", "subnet-0a686c82847f29a8a"]
# }

# variable "private_subnet_a"{
#  description = "Private Subnet CIDR values"
#  default     = "10.0.4.0/24"
# }

# variable "private_subnet_b" {
#   description = "Private subnet south b"
#   default = "10.0.5.0/24"
  
# }
# variable "private_subnet_c" {
#   description = "Private subnet south c"
#   default = "10.0.6.0/24"
  
# }
