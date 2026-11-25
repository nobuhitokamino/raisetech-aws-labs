{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadRdsManagedSecret",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:ap-northeast-1:__ACCOUNT_ID__:secret:rds!*",
      "Condition": {
        "StringEquals": {
          "secretsmanager:ResourceTag/aws:rds:primaryDBInstanceArn": "arn:aws:rds:ap-northeast-1:__ACCOUNT_ID__:db:raisetech-tf-rds"
        }
      }
    },
    {
      "Sid": "DescribeApplicationLogStreams",
      "Effect": "Allow",
      "Action": "logs:DescribeLogStreams",
      "Resource": "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application"
    },
    {
      "Sid": "WriteApplicationLogStreams",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:ap-northeast-1:__ACCOUNT_ID__:log-group:/raisetech/terraform/application:log-stream:*"
    },
    {
      "Sid": "DescribeLogGroupsInTokyo",
      "Effect": "Allow",
      "Action": "logs:DescribeLogGroups",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-1"
        }
      }
    }
  ]
}
