# ec2-assume-role

**How to Configure an EC2 Instance to Assume a Role in other AWS Accounts**

Amazon recommends against using AWS Keys on an EC2 Instance to make API calls to AWS.  
The preferred method is to assign a role to an EC2 Instance as described in this [reference document](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#attach-iam-role).  
This guideline discusses a proof of concept script that illustrates how a python program can assume a
role attached to an EC2 instance.

## Accounts
For the purposes of this proof-of-concept script, the following accounts will be used.  Be sure to
change them for your environment:
```
000000000000 <--This the account that hosts the EC2 instance that assumes a role in other accounts
111111111111 <--This the account that the EC2 Instance will assume the PerformSecurityAudit Role in
222222222222 <--The EC2 instance can assume the same role in this account
```


## Setup
This document assumes that assumable roles have been configured in one or more AWS accounts,
other than the account which hosts the EC2 instance.  For this example, we will be using the
"PerformSecurityAudit" Role, which is configured in all of the AWS Accounts in the Domain.  
For Reference, here is the trust policy that is attached to the role as it is configured
in each account:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::000000000000:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

This trust policy allows the role to be assumed from another account.  In this case the
000000000000 account is the account hosting the EC2 instance.

Note that there are also permission policies that need to be attached to the role.  
For this role, two standard policies (ReadOnlyAccess and SecurityAudit) are attached.
In the 000000000000 account, there is a role defined for the EC2 instance to assume.  
The role is named "EC2_PerformSecurityAudit" and here is the policy:
```
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": [
            "arn:aws:iam::111111111111:role/PerformSecurityAudit",
            "arn:aws:iam::222222222222:role/PerformSecurityAudit"
        ]
    }
}
```

## Launch EC2 Instance with Initialization Script
Normally, automation would be used to launch the EC2 instance, but for this proof of concept use the console to launch an EC2 instance using the latest Amazon Linux AMI.

Configure the other EC2 instance details including Security Group and Required Tags.  In Step 3: Configure Instance Details, provide the file name of the initialization script to be run at boot time, as shown below:

![alt text](../master/images/choose_init_file.png "Choose Initialization File")

Lastly, don't forget to attach the role to the EC2 Instance via the console or the script will not be able to assume the role:

![alt text](../master/images/attach_role.png "Attach role to EC2 Instance")
