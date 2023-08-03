aws logs create-log-group --log-group-name 'arun-logs'
aws s3 mb s3://arun0213b
echo '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:*",
            "Resource": ["arn:aws:s3:::arun0213b", "arn:aws:s3:::arun0213b/*"]
        }
    ]
}' > bucketpolicy.json
aws s3api put-bucket-policy --bucket arun0213b --policy file://bucketpolicy.json
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' > trailrole.json
aws iam create-role --role-name trailrole --assume-role-policy-document file://trailrole.json
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}' > trailpolicy.json
aws iam create-policy --policy-name trailpolicy --policy-document file://trailpolicy.json
trailpolicy_arn=$(aws iam list-policies --query 'Policies[?PolicyName==`trailpolicy`].Arn' --output text)
aws iam attach-role-policy --role-name trailrole --policy-arn $trailpolicy_arn
trailrole_arn=$(aws iam get-role --role-name trailrole --query 'Role.Arn' --output text)
loggroup_arn=$(aws logs describe-log-groups --log-group-name-prefix arun-logs --query 'logGroups[0].arn' --output text)
aws cloudtrail create-trail --name arun0213cloudtrail --s3-bucket-name arun0213b --no-is-multi-region-trail --cloud-watch-logs-role-arn $trailrole_arn --cloud-watch-logs-log-group-arn $loggroup_arn
aws cloudtrail start-logging --name arun0213cloudtrail