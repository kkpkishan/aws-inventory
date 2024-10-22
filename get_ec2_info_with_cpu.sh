#!/bin/bash

# Define the CSV output file and log file
output_file="ec2_instances_info.csv"
log_file="ec2_script_log.txt"

# Initialize log file
echo "----- Script started at $(date) -----" > $log_file

# Write the CSV header with the new format
echo "InstanceId,State,TagName,InstanceType,CPUUtilization(%),TotalEBSSize(GiB),EBSVolumeIds" > $output_file
echo "CSV file initialized at $(date)" >> $log_file

# Fetch EC2 instances details using AWS CLI
instances=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags[?Key==`Name`].Value | [0]]' --output text)

# Log the number of instances found
instance_count=$(echo "$instances" | wc -l)
echo "$instance_count EC2 instances found." >> $log_file

# Check if any instances were found
if [ $instance_count -eq 0 ]; then
    echo "No EC2 instances found. Exiting..." >> $log_file
    exit 0
fi

# Loop through the fetched instances
while IFS= read -r line; do
    instance_id=$(echo $line | awk '{print $1}')
    instance_state=$(echo $line | awk '{print $2}')
    instance_type=$(echo $line | awk '{print $3}')
    tag_name=$(echo $line | awk '{print $4}')
    
    # Log instance details
    echo "Processing Instance: $instance_id, State: $instance_state, Type: $instance_type, Tag: $tag_name" >> $log_file

    # Fetch attached EBS volumes for this instance
    ebs_volumes=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instance_id --query 'Volumes[*].[VolumeId,Size]' --output text)
    
    # Log the result of the volume query
    echo "EBS Volumes for instance $instance_id: $ebs_volumes" >> $log_file

    # Initialize variables to hold the total size and volume IDs
    total_size=0
    volume_ids=""

    # Check if any volumes are returned
    if [[ -z "$ebs_volumes" ]]; then
        # Log no attached volumes
        echo "No EBS volumes attached to instance $instance_id" >> $log_file
        total_size=0
        volume_ids="N/A"
    else
        # Loop through attached volumes
        while read -r ebs_volume; do
            volume_id=$(echo $ebs_volume | awk '{print $1}')
            volume_size=$(echo $ebs_volume | awk '{print $2}')
            total_size=$((total_size + volume_size))

            # Append to the list of volume IDs
            if [[ -z "$volume_ids" ]]; then
                volume_ids="$volume_id"
            else
                volume_ids="$volume_ids,$volume_id"
            fi
        done <<< "$ebs_volumes"
    fi

    # Fetch CPU utilization from CloudWatch for the past 6 hours
    cpu_utilization=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/EC2 \
        --metric-name CPUUtilization \
        --dimensions Name=InstanceId,Value=$instance_id \
        --start-time $(date -u -d '6 hours ago' +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 3600 \
        --statistics Maximum \
        --query 'Datapoints[0].Maximum' \
        --output text)

    # Handle cases where CPU data is missing or invalid
    if [[ "$cpu_utilization" == "None" || -z "$cpu_utilization" ]]; then
        cpu_utilization="N/A"
    else
        cpu_utilization=$(printf "%.2f" "$cpu_utilization")
    fi

    # Log CPU utilization
    echo "Instance $instance_id CPU Utilization (6 hours max): $cpu_utilization" >> $log_file

    # Append to CSV in the new format (with CPUUtilization before TotalEBSSize)
    echo "$instance_id,$instance_state,$tag_name,$instance_type,$cpu_utilization,$total_size,$volume_ids" >> $output_file

done <<< "$instances"

# Final log entry
echo "Script completed at $(date)" >> $log_file
echo "EC2 instance information has been saved to $output_file"

# Output the log file to the console for review
cat $log_file
