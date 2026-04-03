resource "aws_autoscaling_group" "AutoScalingAutoScalingGroup" {
    name = "ECS Capacity Provider Spot"
    mixed_instances_policy {
        instances_distribution {
            on_demand_allocation_strategy = "lowest-price"
            on_demand_base_capacity = 0
            on_demand_percentage_above_base_capacity = 0
            spot_allocation_strategy = "lowest-price"
            spot_instance_pools = 2
        }
        launch_template {
            launch_template_specification {
                launch_template_id = var.launch_templates.main.id
                launch_template_name = var.launch_templates.main.name
                version = var.launch_templates.main.version
            }
        }
    }
    min_size = 1
    max_size = 2
    desired_capacity = 1
    default_cooldown = 300

    health_check_type = "EC2"
    health_check_grace_period = 100
    vpc_zone_identifier = var.private_subnet_ids
    termination_policies = [
        "Default"
    ]
    timeouts {
    delete = "20m"
  }
}

resource "aws_autoscaling_group" "TaskAutoScalingGroup" {
    name = "ECS Task Capacity Provider"
    mixed_instances_policy {
        instances_distribution {
            on_demand_allocation_strategy = "lowest-price"
            on_demand_base_capacity = 1
            on_demand_percentage_above_base_capacity = 40
            spot_allocation_strategy = "lowest-price"
            spot_instance_pools = 2
        }
        launch_template {
            launch_template_specification {
                launch_template_id = var.launch_templates.task.id
                launch_template_name = var.launch_templates.task.name
                version = var.launch_templates.task.version
            }
        }
    }
    min_size = 1
    max_size = 2
    desired_capacity = 1
    default_cooldown = 300

    health_check_type = "EC2"
    health_check_grace_period = 100
    vpc_zone_identifier = var.private_subnet_ids
    termination_policies = [
        "Default"
    ]
    timeouts {
    delete = "20m"
  }
}



#############################>>>>>Ecs clusters<<<<<########################
resource "aws_ecs_cluster" "service_cluster" {
  name = "${var.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

}

resource "aws_ecs_cluster" "task_cluster" {
  name = "${var.project_name}-task-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
###############>>>>>capacity-provider<<<<<#################

resource "aws_ecs_capacity_provider" "service-cluster" {
  name = "service-cluster-capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.AutoScalingAutoScalingGroup.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      #minimum_scaling_step_size = 1
     # maximum_scaling_step_size = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "service-cluster-cp" {
  cluster_name = aws_ecs_cluster.service_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.service-cluster.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.service-cluster.name
    weight            = 1
  }
}

resource "aws_ecs_capacity_provider" "task-cluster" {
  name = "service-task-capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.TaskAutoScalingGroup.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      #minimum_scaling_step_size = 1
     # maximum_scaling_step_size = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "task-cluster-cp" {
  cluster_name = aws_ecs_cluster.task_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.task-cluster.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.task-cluster.name
    weight            = 1
  }
}



##############>>>>>>>>ECS services<<<<<<<###########

resource "aws_ecs_service" "crm-service" {
    name = "crm-service"
    cluster = aws_ecs_cluster.service_cluster.arn
    load_balancer {
        target_group_arn = var.crm-internal-ecs-tg
        container_name = "crm-service"
        container_port = 8000
    }
    load_balancer {
        target_group_arn = var.crm-ecs-tg
        container_name = "crm-service"
        container_port = 8000
    }
    desired_count = 3
   # task_definition = "${aws_ecs_task_definition.ECSTaskDefinition.arn}" 
    task_definition = aws_ecs_task_definition.ECSTaskDefinition.arn

    deployment_maximum_percent = 200
    deployment_minimum_healthy_percent = 90
    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.service-cluster.name
      weight            = 1
      base              = 0
    }
    
    ordered_placement_strategy {
        type = "spread"
        field = "attribute:ecs.availability-zone"
    }
    network_configuration {
        assign_public_ip = false
        security_groups = [
           var.crm_service_sgroup_id
        ]
        subnets = var.private_subnet_ids
    }
    health_check_grace_period_seconds = 150
    scheduling_strategy = "REPLICA"
}

resource "aws_ecs_service" "payin-service" {
    name = "Payin-service"
    cluster = aws_ecs_cluster.service_cluster.arn
    load_balancer {
        target_group_arn = var.crm-payin-internal-tg
        container_name = "payin-service"
        container_port = 8000
    }
    load_balancer {
        target_group_arn = var.crm-payin-tg
        container_name = "payin-service"
        container_port = 8000
    }
    desired_count = 3
   # task_definition = "${aws_ecs_task_definition.ECSTaskDefinition.arn}" 
    task_definition = aws_ecs_task_definition.payin-service.arn

    deployment_maximum_percent = 200
    deployment_minimum_healthy_percent = 90
    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.service-cluster.name
      weight            = 1
      base              = 0
    }
    ordered_placement_strategy {
        type = "spread"
        field = "attribute:ecs.availability-zone"
    }
    network_configuration {
        assign_public_ip = false
        security_groups = [
           var.crm_service_sgroup_id
        ]
        subnets = var.private_subnet_ids
    }
    health_check_grace_period_seconds = 150
    scheduling_strategy = "REPLICA"
}

resource "aws_ecs_service" "webhook-worker-service" {
    name = "webhook-worker-service"
    cluster = aws_ecs_cluster.task_cluster.arn
    desired_count = 3
    task_definition = aws_ecs_task_definition.webhook-worker-task.arn
    deployment_maximum_percent = 200
    deployment_minimum_healthy_percent = 40
    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.task-cluster.name
      weight            = 1
      base              = 0
    }
    ordered_placement_strategy {
        type = "binpack"
        field = "cpu"
    }
    network_configuration {
        assign_public_ip = false
        security_groups = [ var.tasks_services_sgroup_id
        ]
        subnets = var.private_subnet_ids
    }
    scheduling_strategy = "REPLICA"
}

resource "aws_ecs_service" "payout-long-running-status-enquiry" {
    name = "payout-long-running-status-enquiry-worker-service"
    cluster =  aws_ecs_cluster.task_cluster.arn
    desired_count = 0
    task_definition = aws_ecs_task_definition.payout-long-running.arn
    deployment_maximum_percent = 200
    deployment_minimum_healthy_percent = 40
    
    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.task-cluster.name
      weight            = 1
      base              = 0
    }

    ordered_placement_strategy {
        type = "binpack"
        field = "cpu"
    }
    network_configuration {
        assign_public_ip = false
        security_groups = [
            var.tasks_services_sgroup_id
        ]
        subnets = var.private_subnet_ids
    }
    scheduling_strategy = "REPLICA"
}

resource "aws_ecs_service" "payout-refund-worker-service" {
    name = "payout-refund-worker-service"
    cluster = aws_ecs_cluster.task_cluster.arn
    desired_count = 1
    task_definition = aws_ecs_task_definition.payout-refund-worker-task.arn
    deployment_maximum_percent = 200
    deployment_minimum_healthy_percent = 40
    
    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.task-cluster.name
      weight            = 1
      base              = 0
    }    
    ordered_placement_strategy {
        type = "binpack"
        field = "cpu"
    }
    network_configuration {
        assign_public_ip = false
        security_groups = [
           var.tasks_services_sgroup_id
        ]
        subnets = var.private_subnet_ids
    }
    scheduling_strategy = "REPLICA"
}

resource "aws_ecs_service" "celery-beat-worker" {
    name = "celery-beat-worker-service"
    cluster = aws_ecs_cluster.task_cluster.arn
    desired_count = 1
    task_definition = aws_ecs_task_definition.celery-beat-worker-task.arn
    deployment_maximum_percent = 200
    deployment_minimum_healthy_percent = 10
    
    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.task-cluster.name
      weight            = 1
      base              = 0
    }    
    ordered_placement_strategy {
        type = "binpack"
        field = "cpu"
    }
    network_configuration {
        assign_public_ip = false
        security_groups = [
          var.crm_service_sgroup_id
        ]
        subnets = var.private_subnet_ids
    }
    scheduling_strategy = "REPLICA"
}


resource "aws_ecs_service" "celery-worker-service" {
    name = "celery-worker-service"
    cluster = aws_ecs_cluster.task_cluster.arn
    desired_count = 1
    task_definition = aws_ecs_task_definition.celery-worked-recon-task.arn
    deployment_maximum_percent = 200
    deployment_minimum_healthy_percent = 40
    
    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.task-cluster.name
      weight            = 1
      base              = 0
    }    
    ordered_placement_strategy {
        type = "binpack"
        field = "cpu"
    }
    network_configuration {
        assign_public_ip = false
        security_groups = [
            var.crm_service_sgroup_id
        ]
        subnets = var.private_subnet_ids
    }
    scheduling_strategy = "REPLICA"
}
