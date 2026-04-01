resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    name = "db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_nick_name}-postgres-db"
  db_name           = "${var.project_name}_prod"
  engine            = "postgres"
  engine_version    = "13.20"
  instance_class    = "db.t3.small"  # Adjust instance type as needed
  allocated_storage = 50             # Adjust storage as needed
  username          = "${var.project_name}_user"
  password          = var.dbpassword
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot = true

  tags = {
    name = "${var.project_name}-postgres-db"
  }
}


resource "aws_elasticache_subnet_group" "redis-subnet-group" {
  name       = "redis-subnet-group"
  subnet_ids = var.private_subnets # replace with your actual subnet IDs

  tags = {
    name = "redis-subnet-group"
  }
}

resource "aws_elasticache_replication_group" "example" {
  replication_group_id          = "tf-rep-group"
  node_type                     = "cache.t4g.small"  # choose an appropriate instance type
  num_cache_clusters            = 3
  engine                        = "redis"
  engine_version                = "6.2"
  subnet_group_name             = aws_elasticache_subnet_group.redis-subnet-group.name
  security_group_ids            =  [var.redis_sg_id]
  description = "redis cache cluster"
  apply_immediately = true
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  automatic_failover_enabled = true

  tags = {
    name = "${var.project_name}-cache"
  }

}