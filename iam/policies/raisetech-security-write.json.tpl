{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateTaggedSecurityGroups",
      "Effect": "Allow",
      "Action": "ec2:CreateSecurityGroup",
      "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:security-group/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:RequestTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "CreateSecurityGroupsInTaggedVpc",
      "Effect": "Allow",
      "Action": "ec2:CreateSecurityGroup",
      "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:vpc/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "TagSecurityGroupsDuringCreation",
      "Effect": "Allow",
      "Action": "ec2:CreateTags",
      "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:security-group/*",
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": "CreateSecurityGroup",
          "aws:RequestTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "DeleteTaggedSecurityGroups",
      "Effect": "Allow",
      "Action": "ec2:DeleteSecurityGroup",
      "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:security-group/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "ManageRulesInTaggedSecurityGroups",
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupEgress"
      ],
      "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:security-group/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "CreateTaggedSecurityGroupRules",
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress"
      ],
      "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:security-group-rule/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:RequestTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "TagSecurityGroupRulesDuringCreation",
      "Effect": "Allow",
      "Action": "ec2:CreateTags",
      "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:security-group-rule/*",
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "AuthorizeSecurityGroupIngress",
            "AuthorizeSecurityGroupEgress"
          ],
          "aws:RequestTag/Project": "raisetech-aws-labs"
        }
      }
    }
  ]
}
