#!/bin/bash

# Define the CSV output file and log file
output_file="rds_instances_info.csv"
log_file="rds_script_log.txt"

# Initialize log file
echo "----- Script started at $(date) -----" > $log_file

# Write the CSV header with the desired format
echo "InstanceId,InstanceType,DBInstanceClass,CPUUtilization(%),AllocatedStorage(GiB),DBInstanceStatus" > $output_file
echo "CSV file initialized at $(date)" >> $log_file

# Fetch RDS instance details using AWS CLI
rds_instances=$(aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus,AllocatedStorage]' --output text)

# Log the number of RDS instances found
rds_instance_count=$(echo "$rds_instances" | wc -l)
echo "$rds_instance_count RDS instances found." >> $log_file

# Check if any instances were found
if [ $rds_instance_count -eq 0 ]; then
    echo "No RDS instances found. Exiting..." >> $log_file
    exit 0
fi

# Loop through the fetched RDS instances
while IFS= read -r line; do
    instance_id=$(echo $line | awk '{print $1}')
    instance_type=$(echo $line | awk '{print $2}')
    db_instance_status=$(echo $line | awk '{print $3}')
    allocated_storage=$(echo $line | awk '{print $4}')
    
    # Log instance details
    echo "Processing RDS Instance: $instance_id, Status: $db_instance_status, Type: $instance_type, Storage: $allocated_storage GiB" >> $log_file

    # Fetch CPU utilization from CloudWatch for the past 6 hours
    cpu_utilization=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/RDS \
        --metric-name CPUUtilization \
        --dimensions Name=DBInstanceIdentifier,Value=$instance_id \
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
    echo "RDS Instance $instance_id CPU Utilization (6 hours max): $cpu_utilization" >> $log_file

    # Append to CSV
    echo "$instance_id,$instance_type,$allocated_storage GiB,$cpu_utilization,$db_instance_status" >> $output_file

done <<< "$rds_instances"

# Final log entry
echo "Script completed at $(date)" >> $log_file
echo "RDS instance information has been saved to $output_file"

# Output the log file to the console for review
cat $log_file
