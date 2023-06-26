#!/bin/bash

# Fetch all AWS regions
for region in $(aws ec2 describe-regions --output text --query 'Regions[].RegionName')
do
  echo "Checking region $region"

  # Fetch all Elastic IPs not allocated to a network interface
  for allocation in $(aws ec2 describe-addresses --region "$region" --query "Addresses[?AssociationId==null].AllocationId" --output text)
  do
    echo "Releasing unattached Elastic IP with allocation id $allocation in region $region"
    aws ec2 release-address --region "$region" --allocation-id "$allocation"
  done

  # Add other services and their corresponding commands here
  # ...

done
