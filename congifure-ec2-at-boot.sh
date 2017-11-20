#!/bin/bash
logfile=/tmp/setup.log
echo "START" > logfile
exec > $logfile 2>&1  # Log stdout and std to logfile in /tmp

# Script to configure Linux host after launchtime

# Check for root
[ "$(id -u)" -ne 0 ] && echo "Incorrect Permissions - Run this script as root" && exit 1

TIMESTAMP=$(date)

echo; echo "== Install Updates & Dependencies"
yum -y update
yum install -y python36
python3 -m pip install boto3

echo; echo "== Turn on Process Accounting"
chkconfig psacct on

echo; echo "== Setup AWS EC2 Instance to Assume the PerformSecurityAuditRole"
# Create a simple POC python script that demonstates programmatic role assumption
echo; echo "==== Create Python Script to Assume a Role"
cat << EOF > /home/ec2-user/ec2-assume-role.py
import boto3

def role_to_session(**kwargs):
   """
   Usage :
       session = role_to_session(
           RoleArn='arn:aws:iam::012345678901:role/example-role',
           RoleSessionName='ExampleSessionName')
       client = session.client('sqs')
   """
   client = boto3.client('sts')
   response = client.assume_role(**kwargs)
   return boto3.Session(
       aws_access_key_id=response['Credentials']['AccessKeyId'],
       aws_secret_access_key=response['Credentials']['SecretAccessKey'],
       aws_session_token=response['Credentials']['SessionToken'],
       region_name='us-east-1')


#ec2 = boto3.client('ec2')
session = role_to_session(
   RoleArn='arn:aws:iam::111111111111:role/PerformSecurityAudit',
   RoleSessionName='TestSessionName')
ec2 = session.client('ec2')

# As proof that the role assumption worked this script just
# retrieves all regions/endpoints that work with EC2
response = ec2.describe_regions()
print('Regions:', response['Regions'])
EOF

echo; echo "==== Create a Shell Script to Schedule with cron"
cat << EOF > /home/ec2-user/ec2-assume-role.sh
#!/bin/bash
echo "========================" >> /home/ec2-user/ec2-assume-role.log
date >> /home/ec2-user/ec2-assume-role.log
python3 /home/ec2-user/ec2-assume-role.py >> /home/ec2-user/ec2-assume-role.log
EOF
echo; echo "==== Change to ownership unpriviledged ec2-user"
chmod 500 /home/ec2-user/ec2-assume-role.sh
chown ec2-user:ec2-user /home/ec2-user/ec2-assume-role.*
echo; echo "==== Schedule cron job"
# For demo purposes will run every five minutes
(crontab -u ec2-user -l ; echo "*/5 * * * * /home/ec2-user/ec2-assume-role.sh") | crontab -u ec2-user -
echo '** NOTE: An output of "no crontab for ec2-user" is expected'
echo 'new crontab:'
crontab -u ec2-user -l

echo; echo "== SCRIPT COMPLETE"
echo; echo "== $0 has completed"
