#!/bin/bash

# Get current date
current_date=$(date +%s)

# Calculate date 6 months ago
six_months_ago=$(date -d "6 months ago" +%s)

# Get all users
users=$(aws iam list-users --query "Users[*].UserName" --output text)

# For each user
for user in $users
do
  echo "Checking user $user"
  
  # Get their access keys
  keys=$(aws iam list-access-keys --user-name $user --query "AccessKeyMetadata[*].AccessKeyId" --output text)
  
  # For each access key
  for key in $keys
  do
    echo "Checking access key $key of user $user"
    
    # Get the last used date for the key
    last_used_date=$(aws iam get-access-key-last-used --access-key-id $key | jq -r ".AccessKeyLastUsed.LastUsedDate")
    
    # If last used date is empty, assume the key as not used
    if [ "$last_used_date" == "null" ]
    then
      echo "Key $key of user $user has never been used. Deactivating..."
      aws iam update-access-key --user-name $user --access-key-id $key --status Inactive
      continue
    fi
    
    # Convert last used date to Unix timestamp
    last_used_date_unix=$(date -d"$last_used_date" +%s)
    
    # Check if key was used in the last 6 months
    if (( last_used_date_unix < six_months_ago ))
    then
      echo "Key $key of user $user has not been used for 6 months. Deactivating..."
      aws iam update-access-key --user-name $user --access-key-id $key --status Inactive
    fi
  done
done
