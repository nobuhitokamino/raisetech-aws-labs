{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CreateTaggedDBSubnetGroup",
            "Effect": "Allow",
            "Action": "rds:CreateDBSubnetGroup",
            "Resource": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:subgrp:raisetech-tf-db-subnet-group",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "TagDBSubnetGroup",
            "Effect": "Allow",
            "Action": "rds:AddTagsToResource",
            "Resource": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:subgrp:raisetech-tf-db-subnet-group",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "CreateTaggedMySQLInstance",
            "Effect": "Allow",
            "Action": "rds:CreateDBInstance",
            "Resource": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:db:raisetech-tf-rds",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:RequestTag/Project": "raisetech-aws-labs",
                    "rds:DatabaseEngine": "mysql",
                    "rds:DatabaseClass": "db.t3.micro"
                },
                "Bool": {
                    "rds:StorageEncrypted": "true",
                    "rds:PubliclyAccessible": "false",
                    "rds:MultiAz": "false",
                    "rds:ManageMasterUserPassword": "true"
                },
                "NumericEquals": {
                    "rds:StorageSize": 20
                }
            }
        },
        {
            "Sid": "UseApprovedGroupsForDBInstanceCreation",
            "Effect": "Allow",
            "Action": "rds:CreateDBInstance",
            "Resource": [
                "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:subgrp:raisetech-tf-db-subnet-group",
                "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:pg:default.mysql8.0",
                "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:pg:default.mysql8.4",
                "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:og:default:mysql-8-0",
                "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:og:default:mysql-8-4"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "TagApplicationDBInstance",
            "Effect": "Allow",
            "Action": "rds:AddTagsToResource",
            "Resource": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:db:raisetech-tf-rds",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:RequestTag/Project": "raisetech-aws-labs"
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
            "Sid": "CreateRDSManagedSecret",
            "Effect": "Allow",
            "Action": "secretsmanager:CreateSecret",
            "Resource": "arn:aws:secretsmanager:ap-northeast-1:__ACCOUNT_ID__:secret:rds!db-*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "TagRDSManagedSecret",
            "Effect": "Allow",
            "Action": "secretsmanager:TagResource",
            "Resource": "arn:aws:secretsmanager:ap-northeast-1:__ACCOUNT_ID__:secret:rds!db-*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "DescribeSecretsManagerKMSKey",
            "Effect": "Allow",
            "Action": "kms:DescribeKey",
            "Resource": "arn:aws:kms:ap-northeast-1:__ACCOUNT_ID__:key/__KMS_KEY_ID__"
        },
        {
            "Sid": "ReadApplicationDBInstance",
            "Effect": "Allow",
            "Action": "rds:DescribeDBInstances",
            "Resource": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:db:*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "ReadApplicationDBSubnetGroup",
            "Effect": "Allow",
            "Action": "rds:DescribeDBSubnetGroups",
            "Resource": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:subgrp:raisetech-tf-db-subnet-group",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "ReadApplicationRDSTags",
            "Effect": "Allow",
            "Action": "rds:ListTagsForResource",
            "Resource": [
                "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:db:raisetech-tf-rds",
                "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:subgrp:raisetech-tf-db-subnet-group"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1"
                }
            }
        },
        {
            "Sid": "DeleteTaggedDBInstance",
            "Effect": "Allow",
            "Action": "rds:DeleteDBInstance",
            "Resource": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:db:raisetech-tf-rds",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        },
        {
            "Sid": "DeleteTaggedDBSubnetGroup",
            "Effect": "Allow",
            "Action": "rds:DeleteDBSubnetGroup",
            "Resource": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:subgrp:raisetech-tf-db-subnet-group",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "ap-northeast-1",
                    "aws:ResourceTag/Project": "raisetech-aws-labs"
                }
            }
        }
    ]
}
