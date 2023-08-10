#vol file, comma wo spaces
#vol-0bd38267aba0ebd6d,vol-0496df42d6c2db2cf,vol-0c2b95462384ff555,vol-0cb044883e8afbdd0,vol-052e5881e7ba6a494,vol-0d9b19c1524f1f61c,vol-0f4473b9dcc12cf19,vol-0d0ab731fa9762454,vol-0403e187ce8ae60a7,vol-0ec46017e4227db09


#!/bin/bash

# Define the path to your file
FILE_PATH="/home/cloudshell-user/vol"

# Read volume IDs from the file
VOLUME_IDS=$(cat $FILE_PATH | tr ',' ' ')

# Loop over each volume ID and attempt to delete
for VOL in $VOLUME_IDS; do
    echo "Deleting volume: $VOL"
    aws ec2 delete-volume --volume-id $VOL
done