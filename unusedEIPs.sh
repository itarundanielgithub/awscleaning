#!/bin/bash

# Fetch all AWS regions
for region in $(aws ec2 describe-regions --output text --query 'Regions[].RegionName')
do
  echo "Checking region $region"
  
  # Fetch all Elastic IPs
  for allocation in $(aws ec2 describe-addresses --region "$region" --query "Addresses[?InstanceId==null].AllocationId" --output text)
  do
    echo "Releasing unattached Elastic IP with allocation id $allocation in region $region"
    aws ec2 release-address --region "$region" --allocation-id "$allocation"
  done
done
