{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateRaiseTechSNSTopic",
      "Effect": "Allow",
      "Action": "sns:CreateTopic",
      "Resource": "arn:aws:sns:ap-northeast-1:__ACCOUNT_ID__:raisetech-tf-monitoring-alerts",
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
      "Sid": "TagRaiseTechSNSTopic",
      "Effect": "Allow",
      "Action": "sns:TagResource",
      "Resource": "arn:aws:sns:ap-northeast-1:__ACCOUNT_ID__:raisetech-tf-monitoring-alerts",
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
      "Sid": "ReadRaiseTechSNSTopic",
      "Effect": "Allow",
      "Action": [
        "sns:GetTopicAttributes",
        "sns:ListTagsForResource"
      ],
      "Resource": "arn:aws:sns:ap-northeast-1:__ACCOUNT_ID__:raisetech-tf-monitoring-alerts",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "ManageTaggedRaiseTechSNSTopicAttributes",
      "Effect": "Allow",
      "Action": "sns:SetTopicAttributes",
      "Resource": "arn:aws:sns:ap-northeast-1:__ACCOUNT_ID__:raisetech-tf-monitoring-alerts",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "DeleteTaggedRaiseTechSNSTopic",
      "Effect": "Allow",
      "Action": "sns:DeleteTopic",
      "Resource": "arn:aws:sns:ap-northeast-1:__ACCOUNT_ID__:raisetech-tf-monitoring-alerts",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "SubscribeRaiseTechMonitoringEmail",
      "Effect": "Allow",
      "Action": "sns:Subscribe",
      "Resource": "arn:aws:sns:ap-northeast-1:__ACCOUNT_ID__:raisetech-tf-monitoring-alerts",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs",
          "sns:Protocol": "email",
          "sns:Endpoint": "__NOTIFICATION_EMAIL__"
        }
      }
    },
    {
      "Sid": "ManageRaiseTechMonitoringSubscription",
      "Effect": "Allow",
      "Action": [
        "sns:GetSubscriptionAttributes",
        "sns:Unsubscribe"
      ],
      "Resource": "arn:aws:sns:ap-northeast-1:__ACCOUNT_ID__:raisetech-tf-monitoring-alerts",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    }
  ]
}
