output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "redis_enpoint" {
    value = {
        primary_endpoint_address = aws_elasticache_replication_group.example.primary_endpoint_address
        reader_endpoint_address = aws_elasticache_replication_group.example.reader_endpoint_address
    }
}