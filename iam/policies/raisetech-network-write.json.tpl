{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CreateTaggedSubnets",
            "Effect": "Allow",
            "Action": "ec2:CreateSubnet",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:subnet/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "UseRaiseTechVpc",
            "Effect": "Allow",
            "Action": "ec2:CreateSubnet",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:vpc/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "TagSubnetsDuringCreation",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:subnet/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSubnet",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ManageTaggedSubnets",
            "Effect": "Allow",
            "Action": [
                "ec2:ModifySubnetAttribute",
                "ec2:DeleteSubnet"
            ],
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:subnet/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "CreateTaggedInternetGateway",
            "Effect": "Allow",
            "Action": "ec2:CreateInternetGateway",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:internet-gateway/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "TagInternetGatewayDuringCreation",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:internet-gateway/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateInternetGateway",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ManageTaggedInternetGateway",
            "Effect": "Allow",
            "Action": [
                "ec2:AttachInternetGateway",
                "ec2:DetachInternetGateway",
                "ec2:DeleteInternetGateway"
            ],
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:internet-gateway/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "AttachDetachTaggedVpc",
            "Effect": "Allow",
            "Action": [
                "ec2:AttachInternetGateway",
                "ec2:DetachInternetGateway"
            ],
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:vpc/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "CreateTaggedRouteTable",
            "Effect": "Allow",
            "Action": "ec2:CreateRouteTable",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:route-table/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "CreateRouteTableInTaggedVpc",
            "Effect": "Allow",
            "Action": "ec2:CreateRouteTable",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:vpc/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "TagRouteTableDuringCreation",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:route-table/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateRouteTable",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ManageTaggedRouteTablesAndRoutes",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteRouteTable",
                "ec2:CreateRoute",
                "ec2:ReplaceRoute",
                "ec2:DeleteRoute"
            ],
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:route-table/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ManageTaggedRouteTableAssociations",
            "Effect": "Allow",
            "Action": [
                "ec2:AssociateRouteTable",
                "ec2:DisassociateRouteTable",
                "ec2:ReplaceRouteTableAssociation"
            ],
            "Resource": [
                "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:route-table/*",
                "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:subnet/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "ManageTaggedVpc",
            "Effect": "Allow",
            "Action": [
                "ec2:ModifyVpcAttribute",
                "ec2:DeleteVpc"
            ],
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:vpc/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        }
    ]
}
