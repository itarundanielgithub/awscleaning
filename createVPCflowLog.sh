#!/bin/bash

# Fetching the list of VPCs
VPCS=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output text)

# Display the VPCs to the user
echo "Available VPCs:"
counter=1
declare -A VPC_MAP
for VPC in $VPCS; do
    echo "$counter. $VPC"
    VPC_MAP[$counter]=$VPC
    ((counter++))
done

# Ask the user to choose a VPC
read -p "Enter the number of the VPC to create a Flow Log for: " CHOICE

SELECTED_VPC=${VPC_MAP[$CHOICE]}

# Check if the user's choice is valid
if [ -z "$SELECTED_VPC" ]; then
    echo "Invalid choice!"
    exit 1
fi

# Define CloudWatch Log Group name
LOG_GROUP_NAME="VPCFlowLogs-$SELECTED_VPC"

# Create IAM Role for VPC Flow Logs
ROLE_NAME="VPCFlowLogsRole-$SELECTED_VPC"
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "vpc-flow-logs.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}'
ROLE_ARN=$(aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document "$TRUST_POLICY" --query "Role.Arn" --output text)

# Create Policy for the Role to Publish to CloudWatch Logs
POLICY_NAME="VPCFlowLogsPolicy-$SELECTED_VPC"
POLICY_DOC='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:'$LOG_GROUP_NAME':*"
    }
  ]
}'
aws iam create-policy --policy-name $POLICY_NAME --policy-document "$POLICY_DOC"
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$POLICY_NAME

# Ask the user for log retention period in months
read -p "Enter the retention period for the logs in months: " RETENTION_MONTHS

# Convert months to days (assuming 30 days in a month for simplicity)
RETENTION_DAYS=$(( RETENTION_MONTHS * 30 ))

# Create CloudWatch Log Group
aws logs create-log-group --log-group-name $LOG_GROUP_NAME

# Set Retention Period for the Log Group
aws logs put-retention-policy --log-group-name $LOG_GROUP_NAME --retention-in-days $RETENTION_DAYS

# Create VPC Flow Log for the selected VPC
aws ec2 create-flow-logs --resource-type VPC --resource-ids $SELECTED_VPC --traffic-type ALL --deliver-logs-permission-arn $ROLE_ARN --log-group-name $LOG_GROUP_NAME

echo "VPC Flow Log created for VPC: $SELECTED_VPC"
