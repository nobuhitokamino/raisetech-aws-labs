# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alarm" {
  name = "raisetech-tf-monitoring-alerts"
}

# Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ALB Generated HTTP 5XX Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "raisetech-tf-alb-5xx"
  alarm_description = "Detect ALB-generated HTTP 5XX errors"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"
  statistic   = "Sum"
  period      = 60

  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_full_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# Target Generated HTTP 5XX Alarm
resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name        = "raisetech-tf-target-5xx"
  alarm_description = "Detect target-generated HTTP 5XX errors"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"
  statistic   = "Sum"
  period      = 60

  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_full_name
    TargetGroup  = var.target_group_full_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# Unhealthy Target Alarm
resource "aws_cloudwatch_metric_alarm" "unhealthy_host" {
  alarm_name        = "raisetech-tf-unhealthy-host"
  alarm_description = "Detect unhealthy ALB targets"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Minimum"
  period      = 60

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_full_name
    TargetGroup  = var.target_group_full_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# EC2 CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name        = "raisetech-tf-ec2-high-cpu"
  alarm_description = "Detect high EC2 CPU utilization"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"
  period      = 300

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 70
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "missing"

  dimensions = {
    InstanceId = var.ec2_instance_id
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# RDS Storage Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name        = "raisetech-tf-rds-high-storage"
  alarm_description = "Detect RDS storage utilization over 80 percent"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 80

  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "missing"

  # Original Metric: Free Storage Space
  metric_query {
    id          = "m1"
    return_data = false

    metric {
      namespace   = "AWS/RDS"
      metric_name = "FreeStorageSpace"

      period = 300
      stat   = "Average"

      dimensions = {
        DBInstanceIdentifier = var.rds_instance_identifier
      }
    }
  }

  # Metric Math: Storage Usage Percent
  metric_query {
    id          = "e1"
    expression  = "100*(1-m1/(${var.rds_allocated_storage_gib}*1073741824))"
    label       = "RDS Storage Usage Percent"
    return_data = true
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "raisetech-tf-infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      # 01 - ALB Request Count
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "01 - ALB Request Count"
          region = var.aws_region
          view   = "timeSeries"
          period = 60
          stat   = "Sum"

          metrics = [
            [
              "AWS/ApplicationELB", "RequestCount",
              "LoadBalancer", var.alb_full_name
            ]
          ]
        }
      },

      # 02 - Target Health
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "02 - Target Health"
          region = var.aws_region
          view   = "timeSeries"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB", "HealthyHostCount",
              "LoadBalancer", var.alb_full_name,
              "TargetGroup", var.target_group_full_name,
              {
                stat  = "Minimum"
                label = "Healthy"
              }
            ],
            [
              "AWS/ApplicationELB", "UnHealthyHostCount",
              "LoadBalancer", var.alb_full_name,
              "TargetGroup", var.target_group_full_name,
              {
                stat  = "Maximum"
                label = "Unhealthy"
              }
            ]
          ]
        }
      },

      # 03 - ALB / Target 5XX Errors
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "03 - ALB / Target 5XX Errors"
          region = var.aws_region
          view   = "timeSeries"
          period = 60
          stat   = "Sum"

          metrics = [
            [
              "AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count",
              "LoadBalancer", var.alb_full_name,
              {
                label = "ALB 5XX"
              }
            ],
            [
              "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count",
              "LoadBalancer", var.alb_full_name,
              "TargetGroup", var.target_group_full_name,
              {
                label = "Target 5XX"
              }
            ]
          ]
        }
      },

      # 04 - EC2 CPU Utilization
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "04 - EC2 CPU Utilization"
          region = var.aws_region
          view   = "timeSeries"
          period = 300
          stat   = "Average"

          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }

          metrics = [
            [
              "AWS/EC2", "CPUUtilization",
              "InstanceId", var.ec2_instance_id
            ]
          ]
        }
      },

      # 05 - RDS Free Storage Space
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "05 - RDS Free Storage Space"
          region = var.aws_region
          view   = "timeSeries"
          period = 300
          stat   = "Average"

          metrics = [
            [
              "AWS/RDS", "FreeStorageSpace",
              "DBInstanceIdentifier", var.rds_instance_identifier
            ]
          ]
        }
      },

      # 06 - WAF Allowed / Blocked Requests
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "06 - WAF Allowed / Blocked Requests"
          region = var.aws_region
          view   = "timeSeries"
          period = 60
          stat   = "Sum"

          metrics = [
            [
              "AWS/WAFV2", "AllowedRequests",
              "WebACL", var.waf_metric_name,
              "Rule", "ALL",
              "Region", var.aws_region,
              {
                label = "Allowed"
              }
            ],
            [
              "AWS/WAFV2", "BlockedRequests",
              "WebACL", var.waf_metric_name,
              "Rule", "ALL",
              "Region", var.aws_region,
              {
                label = "Blocked"
              }
            ]
          ]
        }
      }
    ]
  })
}
