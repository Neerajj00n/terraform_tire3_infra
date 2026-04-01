# modules/sg/outputs.tf

output "ecs_security_group_id" {
  value = aws_security_group.ecs_security_group.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb_security_group.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "redis_sg_id" {
  value = aws_security_group.redis_sg.id
}

output "crm_service_sgroup_id" {
  value = aws_security_group.crm-service-sgroup.id
}

output "tasks_services_sgroup_id" {
  value = aws_security_group.tasks-services-sgroup.id
}