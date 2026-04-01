output "ecs-cluster-instance-profile" {
    value = {
        arn = aws_iam_instance_profile.ecs-cluster-instance-profile.arn
        name = aws_iam_instance_profile.ecs-cluster-instance-profile.name
    }
  
}

output "crm-service-role" {
    value = {
        arn = aws_iam_role.crm-service-role.arn
        name = aws_iam_role.crm-service-role.name
    }
  
}

output "ecs_task_role" {
    value = {
        arn = aws_iam_role.ecs_task_role.arn
        name = aws_iam_role.ecs_task_role.name
    }
  
}

output "payout-recon-task-role" {
    value = {
        arn = aws_iam_role.payout-recon-task-role.arn
        name = aws_iam_role.payout-recon-task-role.name
    }
  
}
