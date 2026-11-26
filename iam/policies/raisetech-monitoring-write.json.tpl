{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ManageRaiseTechMetricAlarms",
      "Effect": "Allow",
      "Action": "cloudwatch:PutMetricAlarm",
      "Resource": [
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-alb-5xx",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-target-5xx",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-unhealthy-host",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-ec2-high-cpu",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-rds-high-storage"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        },
        "ForAllValues:StringEquals": {
          "cloudwatch:AlarmActions": "arn:aws:sns:ap-northeast-1:__ACCOUNT_ID__:raisetech-tf-monitoring-alerts"
        },
        "Null": {
          "cloudwatch:AlarmActions": "false"
        }
      }
    },
    {
      "Sid": "TagRaiseTechMetricAlarms",
      "Effect": "Allow",
      "Action": "cloudwatch:TagResource",
      "Resource": [
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-alb-5xx",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-target-5xx",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-unhealthy-host",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-ec2-high-cpu",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-rds-high-storage"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:RequestTag/Project": "raisetech-aws-labs"
        },
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "Project",
            "ManagedBy"
          ]
        }
      }
    },
    {
      "Sid": "ReadRaiseTechMetricAlarms",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListTagsForResource"
      ],
      "Resource": [
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-alb-5xx",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-target-5xx",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-unhealthy-host",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-ec2-high-cpu",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-rds-high-storage"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "DeleteTaggedRaiseTechMetricAlarms",
      "Effect": "Allow",
      "Action": "cloudwatch:DeleteAlarms",
      "Resource": [
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-alb-5xx",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-target-5xx",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-unhealthy-host",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-ec2-high-cpu",
        "arn:aws:cloudwatch:ap-northeast-1:__ACCOUNT_ID__:alarm:raisetech-tf-rds-high-storage"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "ManageRaiseTechDashboard",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutDashboard",
        "cloudwatch:GetDashboard"
      ],
      "Resource": "arn:aws:cloudwatch::__ACCOUNT_ID__:dashboard/raisetech-tf-infrastructure",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "DeleteTaggedRaiseTechDashboard",
      "Effect": "Allow",
      "Action": "cloudwatch:DeleteDashboards",
      "Resource": "arn:aws:cloudwatch::__ACCOUNT_ID__:dashboard/raisetech-tf-infrastructure",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    }
  ]
}
