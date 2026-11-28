{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateRaiseTechALBLogsBucket",
      "Effect": "Allow",
      "Action": "s3:CreateBucket",
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*",
      "Condition": {
        "StringEquals": {
          "s3:LocationConstraint": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "ManageRaiseTechBucketPublicAccessBlock",
      "Effect": "Allow",
      "Action": [
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketPublicAccessBlock"
      ],
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*"
    },
    {
      "Sid": "ManageRaiseTechBucketEncryption",
      "Effect": "Allow",
      "Action": [
        "s3:PutEncryptionConfiguration",
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*"
    },
    {
      "Sid": "TagRaiseTechALBLogsBucket",
      "Effect": "Allow",
      "Action": "s3:TagResource",
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Project": "raisetech-aws-labs"
        },
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "Project",
            "ManagedBy",
            "Name"
          ]
        },
        "Null": {
          "aws:TagKeys": "false"
        }
      }
    },
    {
      "Sid": "ReadRaiseTechALBLogsBucketTags",
      "Effect": "Allow",
      "Action": "s3:ListTagsForResource",
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*"
    },
    {
      "Sid": "RemoveRaiseTechALBLogsBucketNameTag",
      "Effect": "Allow",
      "Action": "s3:UntagResource",
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*",
      "Condition": {
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "Name"
          ]
        },
        "Null": {
          "aws:TagKeys": "false"
        }
      }
    },
    {
      "Sid": "ManageRaiseTechBucketLifecycle",
      "Effect": "Allow",
      "Action": [
        "s3:PutLifecycleConfiguration",
        "s3:GetLifecycleConfiguration"
      ],
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*"
    },
    {
      "Sid": "ManageRaiseTechALBLogsBucketPolicy",
      "Effect": "Allow",
      "Action": [
        "s3:PutBucketPolicy",
        "s3:GetBucketPolicy",
        "s3:DeleteBucketPolicy"
      ],
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*"
    },
    {
      "Sid": "ReadRaiseTechALBLogsBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketAcl",
        "s3:GetBucketCORS",
        "s3:GetBucketWebsite",
        "s3:GetBucketVersioning",
        "s3:GetAccelerateConfiguration",
        "s3:GetBucketRequestPayment",
        "s3:GetBucketLogging",
        "s3:GetReplicationConfiguration",
        "s3:GetBucketObjectLockConfiguration",
        "s3:ListBucketVersions"
      ],
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*"
    },
    {
      "Sid": "DeleteRaiseTechALBLogObjects",
      "Effect": "Allow",
      "Action": [
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ],
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*/*",
      "Condition": {
        "StringEquals": {
          "s3:ResourceAccount": "__ACCOUNT_ID__"
        }
      }
    },
    {
      "Sid": "DeleteRaiseTechALBLogsBucket",
      "Effect": "Allow",
      "Action": "s3:DeleteBucket",
      "Resource": "arn:aws:s3:::raisetech-tf-alb-logs-*"
    }
  ]
}
