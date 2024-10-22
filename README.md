# AWS EC2 and RDS Monitoring Scripts

This repository contains two Bash scripts to retrieve details about **EC2** and **RDS** instances, including maximum CPU utilization over the last 6 hours, storage details (EBS for EC2 and Allocated Storage for RDS), and other instance-specific information. The output is written to a CSV file for each script.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Scripts](#scripts)
  - [EC2 Monitoring Script](#ec2-monitoring-script)
  - [RDS Monitoring Script](#rds-monitoring-script)
- [Usage](#usage)
  - [Running the EC2 Script](#running-the-ec2-script)
  - [Running the RDS Script](#running-the-rds-script)
- [CSV Output Format](#csv-output-format)

---

## Overview

These scripts:
- Retrieve EC2 or RDS instance details using AWS CLI.
- Fetch the maximum CPU utilization over the past 6 hours from AWS CloudWatch.
- Output the results to a CSV file with relevant information, including instance type, status, and storage details.

## Prerequisites

- **AWS CLI**: These scripts use AWS CLI to interact with AWS services. Ensure that you have AWS CLI installed and configured with appropriate credentials. You can install it using the following command:
  
  ```bash
  sudo apt-get install awscli
  ```
  
- **AWS IAM Permissions**: The IAM user or role you use must have the following permissions:
  - For EC2: `ec2:DescribeInstances`, `cloudwatch:GetMetricStatistics`, `ec2:DescribeVolumes`
  - For RDS: `rds:DescribeDBInstances`, `cloudwatch:GetMetricStatistics`

- **Bash**: These scripts are designed to run in a Bash shell.

---

## Scripts

### EC2 Monitoring Script

The **EC2 Monitoring Script** retrieves details for all EC2 instances in your AWS account, including:
- Instance ID, state, tag name, instance type.
- Maximum CPU utilization over the last 6 hours.
- Total EBS volume size (in GiB) attached to each instance.
- A list of attached EBS volume IDs.

The output is saved to a CSV file `ec2_instances_info.csv`.

### RDS Monitoring Script

The **RDS Monitoring Script** retrieves details for all RDS instances in your AWS account, including:
- RDS Instance ID, instance type (class), and status.
- Maximum CPU utilization over the last 6 hours.
- Allocated storage (in GiB) for each RDS instance.

The output is saved to a CSV file `rds_instances_info.csv`.

---

## Usage

### Running the EC2 Script

1. Download or copy the **EC2 Monitoring Script** to your local machine.
   
2. Make the script executable:
   ```bash
   chmod +x get_ec2_info_with_cpu.sh
   ```

3. Run the script:
   ```bash
   ./get_ec2_info_with_cpu.sh
   ```

4. The script will create two files:
   - `ec2_instances_info.csv`: Contains the EC2 instance details and metrics.
   - `ec2_script_log.txt`: Contains detailed logs of the script’s execution.

### Running the RDS Script

1. Download or copy the **RDS Monitoring Script** to your local machine.

2. Make the script executable:
   ```bash
   chmod +x get_rds_info_with_cpu.sh
   ```

3. Run the script:
   ```bash
   ./get_rds_info_with_cpu.sh
   ```

4. The script will create two files:
   - `rds_instances_info.csv`: Contains the RDS instance details and metrics.
   - `rds_script_log.txt`: Contains detailed logs of the script’s execution.

---

## CSV Output Format

### EC2 CSV Output Format

| Column               | Description                                                |
|----------------------|------------------------------------------------------------|
| InstanceId           | The ID of the EC2 instance                                  |
| State                | The current state of the instance (e.g., running, stopped)  |
| TagName              | The value of the `Name` tag assigned to the instance        |
| InstanceType         | The type of EC2 instance (e.g., `t2.micro`, `m5.large`)     |
| CPUUtilization(%)    | The maximum CPU utilization over the last 6 hours           |
| TotalEBSSize(GiB)    | Total size of attached EBS volumes (in GiB)                 |
| EBSVolumeIds         | Comma-separated list of attached EBS volume IDs             |

### RDS CSV Output Format

| Column               | Description                                                |
|----------------------|------------------------------------------------------------|
| InstanceId           | The ID of the RDS instance                                  |
| InstanceType         | The type/class of the RDS instance (e.g., `db.m5.large`)    |
| AllocatedStorage(GiB)| The total allocated storage for the RDS instance (in GiB)   |
| CPUUtilization(%)    | The maximum CPU utilization over the last 6 hours           |
| DBInstanceStatus     | The current status of the RDS instance (e.g., `available`)  |

---

## Troubleshooting

- **Missing Data**: If you encounter `N/A` values for CPU utilization, this may indicate that there was no CPU usage during the selected time period (e.g., the instance was idle).
- **AWS CLI Errors**: Ensure that your AWS CLI is correctly configured with valid credentials by running:
  
  ```bash
  aws configure
  ```

If you encounter any issues, please check the log files (`ec2_script_log.txt` or `rds_script_log.txt`) for detailed error messages and troubleshooting information.

---

## License

This project is open-source and available under the [MIT License](LICENSE).
