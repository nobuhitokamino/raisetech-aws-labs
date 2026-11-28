{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CreateTaggedApplicationLoadBalancer",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:CreateLoadBalancer",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:loadbalancer/app/raisetech-tf-alb/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                },
                "StringEqualsIfExists": {
                    "elasticloadbalancing:Scheme": "internet-facing"
                }
            }
        },
        {
            "Sid": "CreateTaggedTargetGroup",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:CreateTargetGroup",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:targetgroup/raisetech-tf-alb-tg/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "TagResourcesDuringCreation",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:AddTags",
            "Resource": [
                "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:loadbalancer/app/raisetech-tf-alb/*",
                "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:targetgroup/raisetech-tf-alb-tg/*"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticloadbalancing:CreateAction": [
                        "CreateLoadBalancer",
                        "CreateTargetGroup"
                    ],
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "CreateHttpListenerForTaggedALB",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:CreateListener",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:loadbalancer/app/raisetech-tf-alb/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "raisetech-aws-labs",
                    "aws:RequestTag/Project": "raisetech-aws-labs",
                    "elasticloadbalancing:ListenerProtocol": "HTTP"
                }
            }
        },
        {
            "Sid": "TagHttpListenerDuringCreation",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:AddTags",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:listener/app/raisetech-tf-alb/*/*",
            "Condition": {
                "StringEquals": {
                    "elasticloadbalancing:CreateAction": "CreateListener",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "RegisterTargetsToTaggedTargetGroup",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:RegisterTargets",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:targetgroup/raisetech-tf-alb-tg/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "DeleteTaggedHttpListener",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:DeleteListener",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:listener/app/raisetech-tf-alb/*/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ManageTaggedTargetGroupDeletion",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:targetgroup/raisetech-tf-alb-tg/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "DeleteTaggedApplicationLoadBalancer",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:DeleteLoadBalancer",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:loadbalancer/app/raisetech-tf-alb/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ReadLoadBalancingResources",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerAttributes",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DescribeCapacityReservation"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "ModifyTaggedApplicationLoadBalancerAttributes",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:loadbalancer/app/raisetech-tf-alb/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ModifyTaggedTargetGroup",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes"
            ],
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:targetgroup/raisetech-tf-alb-tg/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ModifyTaggedHttpListener",
            "Effect": "Allow",
            "Action": "elasticloadbalancing:ModifyListener",
            "Resource": "arn:aws:elasticloadbalancing:ap-northeast-1:__ACCOUNT_ID__:listener/app/raisetech-tf-alb/*/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        }
    ]
}
