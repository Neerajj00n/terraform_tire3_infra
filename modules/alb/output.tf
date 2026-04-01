output "alb_dns" {
  value = aws_lb.ecs_alb.dns_name
}

output "alb_internal_dns" {
    value = aws_lb.ecs_internal_alb.dns_name
}

output "crm-internal-ecs-tg" {
    value = aws_lb_target_group.crm-internal-ecs-tg.arn
  
}

output "crm-ecs-tg" {
    value = aws_lb_target_group.crm-ecs-tg.arn
}

output "crm-payin-tg" {
    value = aws_lb_target_group.crm-payin-tg.arn
}
output "crm-payin-internal-tg" {
    value = aws_lb_target_group.crm-payin-tg.arn
}