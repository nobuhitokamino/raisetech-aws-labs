{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateRaiseTechWebACL",
      "Effect": "Allow",
      "Action": "wafv2:CreateWebACL",
      "Resource": "arn:aws:wafv2:ap-northeast-1:__ACCOUNT_ID__:regional/webacl/raisetech-tf-waf/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:RequestTag/Project": "raisetech-aws-labs",
          "aws:RequestTag/Name": "raisetech-tf-waf"
        },
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "Project",
            "ManagedBy",
            "Name"
          ]
        }
      }
    },
    {
      "Sid": "UseManagedRuleSetsForWebACLCreation",
      "Effect": "Allow",
      "Action": "wafv2:CreateWebACL",
      "Resource": "arn:aws:wafv2:ap-northeast-1:__ACCOUNT_ID__:regional/managedruleset/*/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "TagRaiseTechWebACL",
      "Effect": "Allow",
      "Action": "wafv2:TagResource",
      "Resource": "arn:aws:wafv2:ap-northeast-1:__ACCOUNT_ID__:regional/webacl/raisetech-tf-waf/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:RequestTag/Project": "raisetech-aws-labs",
          "aws:RequestTag/Name": "raisetech-tf-waf"
        },
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "Project",
            "ManagedBy",
            "Name"
          ]
        }
      }
    },
    {
      "Sid": "ReadRaiseTechWebACL",
      "Effect": "Allow",
      "Action": [
        "wafv2:GetWebACL",
        "wafv2:ListTagsForResource"
      ],
      "Resource": "arn:aws:wafv2:ap-northeast-1:__ACCOUNT_ID__:regional/webacl/raisetech-tf-waf/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "ManageTaggedRaiseTechWebACL",
      "Effect": "Allow",
      "Action": [
        "wafv2:UpdateWebACL",
        "wafv2:DeleteWebACL"
      ],
      "Resource": "arn:aws:wafv2:ap-northeast-1:__ACCOUNT_ID__:regional/webacl/raisetech-tf-waf/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs",
          "aws:ResourceTag/Name": "raisetech-tf-waf"
        }
      }
    },
    {
      "Sid": "ReadWAFListsAndManagedRulesInTokyo",
      "Effect": "Allow",
      "Action": [
        "wafv2:ListWebACLs",
        "wafv2:ListAvailableManagedRuleGroups",
        "wafv2:DescribeManagedRuleGroup"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "AssociateAndReadRaiseTechWebACL",
      "Effect": "Allow",
      "Action": [
        "wafv2:AssociateWebACL",
        "wafv2:GetWebACLForResource"
      ],
      "Resource": "arn:aws:wafv2:ap-northeast-1:__ACCOUNT_ID__:regional/webacl/raisetech-tf-waf/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "ManageRaiseTechALBWAFAssociation",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateWebACLAssociation",
        "elasticloadbalancing:GetLoadBalancerWebACL"
      ],
      "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:loadbalancer/app/raisetech-tf-alb/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "DisassociateWebACLInTokyo",
      "Effect": "Allow",
      "Action": "wafv2:DisassociateWebACL",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "DisassociateFromTaggedRaiseTechALB",
      "Effect": "Allow",
      "Action": "elasticloadbalancing:DeleteWebACLAssociation",
      "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:loadbalancer/app/raisetech-tf-alb/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    },
    {
      "Sid": "ManageRaiseTechWAFLogging",
      "Effect": "Allow",
      "Action": [
        "wafv2:PutLoggingConfiguration",
        "wafv2:GetLoggingConfiguration",
        "wafv2:DeleteLoggingConfiguration"
      ],
      "Resource": "arn:aws:wafv2:ap-northeast-1:__ACCOUNT_ID__:regional/webacl/raisetech-tf-waf/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1",
          "aws:ResourceTag/Project": "raisetech-aws-labs"
        }
      }
    }
  ]
}
