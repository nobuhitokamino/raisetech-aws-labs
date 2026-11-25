{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateTaggedApplicationRole",
      "Effect": "Allow",
      "Action": "iam:CreateRole",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Project": "raisetech-aws-labs"
        },
        "ArnEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::__ACCOUNT_ID__:policy/RaiseTechEC2PermissionsBoundary"
        }
      }
    },
    {
      "Sid": "ReadApplicationRole",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:ListRoleTags"
      ],
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role"
    },
    {
      "Sid": "AttachApprovedCloudWatchPolicy",
      "Effect": "Allow",
      "Action": "iam:AttachRolePolicy",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role",
      "Condition": {
        "ArnEquals": {
          "iam:PolicyARN": "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
          "iam:PermissionsBoundary": "arn:aws:iam::__ACCOUNT_ID__:policy/RaiseTechEC2PermissionsBoundary"
        }
      }
    },
    {
      "Sid": "DetachApprovedCloudWatchPolicy",
      "Effect": "Allow",
      "Action": "iam:DetachRolePolicy",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role",
      "Condition": {
        "ArnEquals": {
          "iam:PolicyARN": "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        }
      }
    },
    {
      "Sid": "ListApplicationRoleAttachments",
      "Effect": "Allow",
      "Action": "iam:ListAttachedRolePolicies",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role"
    },
    {
      "Sid": "PutApplicationRoleInlinePolicy",
      "Effect": "Allow",
      "Action": "iam:PutRolePolicy",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role",
      "Condition": {
        "ArnEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::__ACCOUNT_ID__:policy/RaiseTechEC2PermissionsBoundary"
        }
      }
    },
    {
      "Sid": "DeleteApplicationRoleInlinePolicy",
      "Effect": "Allow",
      "Action": "iam:DeleteRolePolicy",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role"
    },
    {
      "Sid": "ReadApplicationRoleInlinePolicies",
      "Effect": "Allow",
      "Action": [
        "iam:GetRolePolicy",
        "iam:ListRolePolicies"
      ],
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role"
    },
    {
      "Sid": "TagApplicationRole",
      "Effect": "Allow",
      "Action": "iam:TagRole",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "CreateTaggedApplicationInstanceProfile",
      "Effect": "Allow",
      "Action": "iam:CreateInstanceProfile",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:instance-profile/raisetech-tf-app-instance-profile",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "TagApplicationInstanceProfile",
      "Effect": "Allow",
      "Action": "iam:TagInstanceProfile",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:instance-profile/raisetech-tf-app-instance-profile",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "ManageTaggedApplicationInstanceProfile",
      "Effect": "Allow",
      "Action": [
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:DeleteInstanceProfile"
      ],
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:instance-profile/raisetech-tf-app-instance-profile",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "ReadApplicationInstanceProfile",
      "Effect": "Allow",
      "Action": [
        "iam:GetInstanceProfile",
        "iam:ListInstanceProfileTags"
      ],
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:instance-profile/raisetech-tf-app-instance-profile"
    },
    {
      "Sid": "ListApplicationRoleInstanceProfiles",
      "Effect": "Allow",
      "Action": "iam:ListInstanceProfilesForRole",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role"
    },
    {
      "Sid": "PassApplicationRoleToEC2",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "ec2.amazonaws.com"
        }
      }
    },
    {
      "Sid": "DeleteBoundedApplicationRole",
      "Effect": "Allow",
      "Action": "iam:DeleteRole",
      "Resource": "arn:aws:iam::__ACCOUNT_ID__:role/raisetech-tf-app-role",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        },
        "ArnEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::__ACCOUNT_ID__:policy/RaiseTechEC2PermissionsBoundary"
        }
      }
    }
  ]
}
