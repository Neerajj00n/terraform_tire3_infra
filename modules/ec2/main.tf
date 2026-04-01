


data "aws_ami" "linux2" {
    owners = ["amazon"]
    most_recent = true
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]

    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}

#################>>>>>>Lanuch template<<<<<<<<#########################
resource "aws_launch_template" "main" {
    name = "ecs-service-instance-lt"
    user_data = base64encode(templatefile("${path.module}/template/user_data1.sh",{ 
      main_cluster_name = var.main_cluster_name, 
      logs_bucket = var.logs_bucket}
    ))
    image_id = data.aws_ami.linux2.id

    instance_requirements {
    
    vcpu_count {
      min = 2
      max = 4
    }
    memory_mib {
      min = 4000
      max = 8000
    }

    allowed_instance_types = var.instance_types["main"]

      
    }

    iam_instance_profile {
        arn = var.ecs-cluster-instance-profile
    }
    network_interfaces {
        associate_public_ip_address = false
        device_index = 0
        security_groups = [ var.ecs_security_group
        ]
    }

    block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
    }
  }
    
}

resource "aws_launch_template" "task" {
    name = "ecs-task-instance-lt"
    user_data = base64encode(templatefile("${path.module}/template/user_data2.sh",{ 
      task_cluster_name = var.task_cluster_name,
      logs_bucket = var.logs_bucket}
    ))

    image_id = data.aws_ami.linux2.id
    instance_requirements {
    
    vcpu_count {
      min = 2
      max = 4
    }
    memory_mib {
      min = 4000
      max = 8000
    }

    allowed_instance_types = var.instance_types["task"]

      
    }

    iam_instance_profile {
        arn = var.ecs-cluster-instance-profile
    }
    network_interfaces {
        associate_public_ip_address = false
        device_index = 0
        security_groups = [var.ecs_security_group
        ]
    }

    block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
    }
  }
    
}