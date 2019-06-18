# Course_Using_IPv6_on_AWS

These scripts are for the “Rapidly Deploying IPv6 on AWS” ACloud.Guru Class.

## Chapter3:

These 2 CloudFormation Templates are used in Chapter 3

ipv4-mgmt-vpc.template = Launches an IPv4-only Management VPC

ipv4-app-vpc.template = Launches an IPv4-only Application VPC

These are used in the early chapter of this class to quickly build up the IPv4-only management and application VPCs, which we use as a base for manual configuration of IPv6.

These are based on the AWS QuickStart Templates.
https://aws.amazon.com/quickstart/architecture/compliance-nist/

## Chapter 6:

We use an S3 bucket policy to restrict access based on the source IPv6 address.

s3-bucket-policy.json is a sample of this type of IAM policy used with an S3 bucket.

## Chapter 7:

Then we have 2 different methods of IPv6 CloudFormation Templates (CFTs) for the automation chapter.

dual-app-vpc-method1.template

dual-app-vpc-method2.template

Then we have a comparable AWS CLI script for rapid IPv6 deployment.

awscli-ipv6.sh is a bash script that runs AWS CLI commands to quickly deploy an equivalent VPC named NewIPv6VPC.
