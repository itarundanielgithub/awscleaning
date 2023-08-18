#!/bin/bash


# Get the AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region us-east-1)

# Define trail, log group, and bucket names
TRAIL_NAME="arun3MyCloudTrail"
CLOUDWATCH_LOG_GROUP_NAME="arun3MyCloudTrailLogGroup"
ROLE_NAME="arun3CloudTrail_CW_Role"
POLICY_NAME="arun3CloudTrail_CW_Policy"
S3_BUCKET_NAME="arun3my-cloudtrail-bucket-$ACCOUNT_ID-$(date +%s)"

# Create an S3 bucket for CloudTrail logs
aws s3api create-bucket --bucket $S3_BUCKET_NAME --region us-east-1

# Set the S3 bucket policy to allow CloudTrail to write to it
aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck20150319",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::'$S3_BUCKET_NAME'"
    },
    {
      "Sid": "AWSCloudTrailWrite20150319",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::'$S3_BUCKET_NAME'/AWSLogs/'$ACCOUNT_ID'/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}' --region us-east-1


# Create Role for CloudTrail to CloudWatch
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' --region us-east-1

# Attach policies to the role to allow CloudTrail to publish to CloudWatch Logs
aws iam put-role-policy --role-name $ROLE_NAME --policy-name $POLICY_NAME --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogStream"
      ],
      "Resource": [

        	"arn:aws:logs:us-east-1:'$ACCOUNT_ID':log-group:'$CLOUDWATCH_LOG_GROUP_NAME':*"

      ]
    }
  ]
}' --region us-east-1

# Create CloudWatch Logs log group
aws logs create-log-group --log-group-name $CLOUDWATCH_LOG_GROUP_NAME --region us-east-1

sleep 10

# Create CloudTrail with integration to CloudWatch Logs
aws cloudtrail create-trail --name $TRAIL_NAME \
  --s3-bucket-name $S3_BUCKET_NAME \
  --include-global-service-events \
  --is-multi-region-trail \
  --cloud-watch-logs-log-group-arn "arn:aws:logs:us-east-1:$ACCOUNT_ID:log-group:$CLOUDWATCH_LOG_GROUP_NAME:*" \
  --cloud-watch-logs-role-arn "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" \
  --region us-east-1

# Start logging
aws cloudtrail start-logging --name $TRAIL_NAME --region us-east-1

echo "CloudTrail created and logging started!"
