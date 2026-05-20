# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application" {
  name              = "/starttech/application"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "starttech-app-logs-${var.environment}"
  })
}

resource "aws_cloudwatch_log_group" "ec2_system" {
  name              = "/starttech/ec2/system"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "starttech-system-logs-${var.environment}"
  })
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "starttech-redis-subnet-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "starttech-redis-subnet-${var.environment}"
  })
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "starttech-redis-${var.environment}"
  engine              = "redis"
  node_type           = "cache.t3.micro"
  num_cache_nodes     = 1
  parameter_group_name = "default.redis7"
  engine_version      = "7.0"
  port                = 6379
  subnet_group_name   = aws_elasticache_subnet_group.redis.name
  security_group_ids  = [var.redis_security_group_id]

  tags = merge(var.tags, {
    Name = "starttech-redis-${var.environment}"
  })
}

# CloudWatch Alarms - High CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "starttech-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 300
  statistic          = "Average"
  threshold          = 80
  alarm_description  = "Alarm when CPU exceeds 80% for 10 minutes"
  alarm_actions      = [] # Add SNS topic ARN for notifications

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  tags = merge(var.tags, {
    Name = "starttech-high-cpu-${var.environment}"
  })
}

# CloudWatch Alarm - Healthy Hosts
resource "aws_cloudwatch_metric_alarm" "healthy_hosts" {
  alarm_name          = "starttech-healthy-hosts-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name        = "HealthyHostCount"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Average"
  threshold          = 1
  alarm_description  = "Alarm when healthy hosts drop below 1"
  alarm_actions      = [] # Add SNS topic ARN for notifications

  dimensions = {
    TargetGroup  = var.alb_arn
    LoadBalancer = var.alb_arn
  }

  tags = merge(var.tags, {
    Name = "starttech-healthy-hosts-${var.environment}"
  })
}

# CloudWatch Alarm - Redis CPU
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "starttech-redis-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ElastiCache"
  period             = 300
  statistic          = "Average"
  threshold          = 80
  alarm_description  = "Alarm when Redis CPU exceeds 80%"
  alarm_actions      = [] # Add SNS topic ARN for notifications

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }

  tags = merge(var.tags, {
    Name = "starttech-redis-cpu-${var.environment}"
  })
}
