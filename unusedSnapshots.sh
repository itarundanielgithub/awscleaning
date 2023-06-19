#!/bin/bash

regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

for region in $regions
do
  echo "Processing region: $region"

  snapshotIds=$(aws ec2 describe-snapshots --region $region --owner-ids self --query 'Snapshots[?StartTime<=`2023-01-01`].SnapshotId' --output text)

  if [ -n "$snapshotIds" ]; then
    echo "Deleting snapshots in region: $region"
    for snapshotId in $snapshotIds
    do
      echo "Deleting snapshot: $snapshotId"
      aws ec2 delete-snapshot --region $region --snapshot-id $snapshotId
    done
  else
    echo "No snapshots to delete in region: $region"
  fi
done