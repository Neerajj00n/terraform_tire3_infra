variable "instance_types" {
  type = map(list(string))

  default = {
    main = [
      "c5.*",
      "m6a.*",
      "m6i.*",
      "m5.*",
      "t3a.*",
      "t3.*",
      "m5a.*"
    ]

    task = [
      "c5.*",
      "c6a.*",
      "t3.medium",
      "m5a.large",
      "m6a.large"
    ]
  }
}
variable "ecs-cluster-instance-profile" {
  type = string
}

variable "ecs_security_group" {
  type = string
  
}

variable "logs_bucket" {
    type = string
  
}

variable "task_cluster_name" {
    type = string
  
}

variable "main_cluster_name" {
    type = string
  
}