#!/bin/bash

SG_ID="sg-0e05551e762cffc74"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z0028204BDRGZDDJXZ1I"
DOMAIN_NAME="devopstest.fun"

for instance in $@
do
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text
)

if [ $instance == "frontend" ]; then
  IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query 'Reservations[].Instances[].PublicIpAddress' \
      --output text
)

RECORD_NAME=$DOMAIN_NAME
else
  IP=$(aws ec2 describe-instances \
     --instance-ids $INSTANCE_ID \
     --query 'Reservations[].Instances[].PrivateIpAddress' \
     --output query
  )

  RECORD_NAME=$instance.$DOMAIN_NAME
  
fi
  echo "IP Address is $IP"

aws route53 change-resource-record-sets \
--hosted-zone-id $ZONE_ID \
--change-batch '
{
"Comment" : "Updating Record",
"Changes" : [
    {
    "Actions" : "UPSERT",
    "ResourceRecordSet": {
       "Name" : "'$RECORD_NAME'",
       "Type" : "A",
       "TTL" : 1,
       "ResourcesRecords" : [
         {
           "Value" : "'$IP'"
         }
       
       ]
    }
    }
]
} '

echo "record updated for $instance"
done
