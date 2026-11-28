{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadEC2NetworkResources",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeSubnets",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSecurityGroupRules",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeImages",
        "ec2:DescribeKeyPairs",
        "ec2:DescribeNetworkAcls",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "ec2:DescribeInstanceCreditSpecifications"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    },
    {
      "Sid": "ReadRaiseTechVPCSecurityGroups",
      "Effect": "Allow",
      "Action": "ec2:GetSecurityGroupsForVpc",
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
