{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ReadAL2023AmiParameter",
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:ssm:ap-northeast-1::parameter/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "LaunchTaggedT3MicroInstances",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:instance/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "ec2:InstanceType": "t3.micro",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "TagInstancesDuringLaunch",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:instance/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "RunInstances",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "LaunchFromAmazonOwnedAmi",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:ap-northeast-1::image/ami-*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "ec2:Owner": "amazon"
                }
            }
        },
        {
            "Sid": "UseTaggedSubnetAndSecurityGroup",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": [
                "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:subnet/*",
                "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:security-group/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "CreateNetworkInterfaceDuringLaunch",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:network-interface/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "CreateTaggedEbsVolumeDuringLaunch",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:volume/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "TagEbsVolumeDuringLaunch",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:volume/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "RunInstances",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "UseApprovedKeyPair",
            "Effect": "Allow",
            "Action": "ec2:RunInstances",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:key-pair/__EC2_KEY_NAME__",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "TerminateTaggedInstances",
            "Effect": "Allow",
            "Action": "ec2:TerminateInstances",
            "Resource": "arn:aws:ec2:ap-northeast-1:__ACCOUNT_ID__:instance/*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        }
    ]
}
