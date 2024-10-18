#!/bin/bash

# Constants
IMAGE_ID="ami-0b4f379183e5706b9"
SECURITY_GROUP_ID="sg-0c634c5272237c3b6"
DOMAIN_NAME="devrob.online"
HOSTED_ZONE_ID="Z0446877SYHUO28MLWFR"

# Check if at least one argument is provided
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 instance_name1 [instance_name2 ...]"
    exit 1
fi

# Set instance type to t2.micro
INSTANCE_TYPE="t2.micro"

# Loop through provided instance names
for i in "$@"
do  
    echo "Creating $i instance with type $INSTANCE_TYPE"

    # Create the instance
    IP_ADDRESS=$(aws ec2 run-instances --image-id "$IMAGE_ID" --instance-type "$INSTANCE_TYPE" --security-group-ids "$SECURITY_GROUP_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" | jq -r '.Instances[0].PrivateIpAddress')
    
    if [ -z "$IP_ADDRESS" ]; then
        echo "Failed to create instance $i"
        continue
    fi

    echo "Created $i instance: $IP_ADDRESS"

    # Update Route 53 DNS
    aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --change-batch '
    {
        "Changes": [{
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "'"$i.$DOMAIN_NAME"'",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [{ "Value": "'"$IP_ADDRESS"'" }]
            }
        }]
    }'
done
