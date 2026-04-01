output "main_cluster_name" {
    value = aws_ecs_cluster.service_cluster.name
  
}
output "task_cluster_name" {
    value = aws_ecs_cluster.task_cluster.name
  
}