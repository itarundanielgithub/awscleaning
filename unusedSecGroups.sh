#!/bin/bash

# Fetch all AWS regions
for region in $(aws ec2 describe-regions --output text --query 'Regions[].RegionName')
do
  echo "Checking region $region"
  
  # Fetch all security groups
  for sg in $(aws ec2 describe-security-groups --region "$region" --query "SecurityGroups[?GroupName!='default'].[GroupId]" --output text)
  do
    # Check for security group usage in Network Interfaces
    result=$(aws ec2 describe-network-interfaces --region "$region" --filters Name=group-id,Values="$sg" --query "NetworkInterfaces[*].[GroupId]" --output text)

    if [ -z "$result" ]; then
      echo "Deleting unused security group $sg in region $region"
      aws ec2 delete-security-group --region "$region" --group-id "$sg"
    fi
  done
done
