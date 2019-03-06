# Course_Using_IPv6_on_AWS

These scripts are for the “Running IPv6 on AWS” Class.

These 2 CloudFormation Templates are used in Chapter 3

ipv4-mgmt-vpc.template = Launches an IPv4-only Management VPC
ipv4-app-vpc.template = Launches an IPv4-only Application VPC

These are used in the early classes to quickly build up the IPv4-only management and application VPCs, which we use as a base for manual configuration of IPv6.
These are based on the AWS QuickStart Templates.


Then we have 2 different methods of CFTs for the automation chapter
dual-app-vpc-method1.template
dual-app-vpc-method2.template

Then we have a comparable AWS CLI script for rapid deployment.  This is a bash script that runs AWS CLI commands to quickly deploy an equivalent New VPC.
awscli-ipv6.sh
