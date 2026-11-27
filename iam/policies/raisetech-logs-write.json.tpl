{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateRaiseTechLogGroups",
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": [
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application:*",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:aws-waf-logs-raisetech-tf",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:aws-waf-logs-raisetech-tf:*",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/aws/rds/instance/raisetech-tf-rds/error",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/aws/rds/instance/raisetech-tf-rds/error:*"
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
      "Sid": "TagRaiseTechLogGroups",
      "Effect": "Allow",
      "Action": "logs:TagResource",
      "Resource": [
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application:*",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:aws-waf-logs-raisetech-tf",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:aws-waf-logs-raisetech-tf:*",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/aws/rds/instance/raisetech-tf-rds/error",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/aws/rds/instance/raisetech-tf-rds/error:*"
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
      "Sid": "ManageRaiseTechLogRetention",
      "Effect": "Allow",
      "Action": "logs:PutRetentionPolicy",
      "Resource": [
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application:*",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:aws-waf-logs-raisetech-tf:*",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/aws/rds/instance/raisetech-tf-rds/error:*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "ReadRaiseTechLogGroupTags",
      "Effect": "Allow",
      "Action": "logs:ListTagsForResource",
      "Resource": [
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:aws-waf-logs-raisetech-tf",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/aws/rds/instance/raisetech-tf-rds/error"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "DescribeLogGroupsInTokyo",
      "Effect": "Allow",
      "Action": "logs:DescribeLogGroups",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "DeleteTaggedRaiseTechLogGroups",
      "Effect": "Allow",
      "Action": "logs:DeleteLogGroup",
      "Resource": [
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application:*",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:aws-waf-logs-raisetech-tf",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:aws-waf-logs-raisetech-tf:*",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/aws/rds/instance/raisetech-tf-rds/error",
        "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/aws/rds/instance/raisetech-tf-rds/error:*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    }
  ]
}
