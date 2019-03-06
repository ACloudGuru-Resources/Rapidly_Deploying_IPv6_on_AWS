#!/bin/bash

# Based on VPC bash script article by Bradley Simonin:
# https://medium.com/@brad.simonin/create-an-aws-vpc-and-subnet-using-the-aws-cli-and-bash-a92af4d2e54b

# Variables used in this script:
availabilityZone1="us-west-2a"
availabilityZone2="us-west-2b"
vpcName="NewIPv6VPC"
subnetName1="NewIPv6PublicSubnet1"
subnetName2="NewIPv6PublicSubnet2"
subnetName3="NewIPv6PrivateSubnet1"
subnetName4="NewIPv6PrivateSubnet2"
gatewayName="NewIPv6VPCInternetGateway"
routeTablePublicName="NewIPv6PublicRouteTable"
routeTablePrivateName1="NewIPv6PrivateRouteTable1"
routeTablePrivateName2="NewIPv6PrivateRouteTable2"
vpcCidrBlock="10.50.0.0/16"
subNetCidrBlock1="10.50.10.0/24"
subNetCidrBlock2="10.50.20.0/24"
subNetCidrBlock3="10.50.30.0/24"
subNetCidrBlock4="10.50.40.0/24"

# Start Time
echo "Starting script at time"; date '+%H:%M:%S'
# Create a VPC with an IPv4 CIDR block and allocate an AWS IPv6 /56 Prefix
echo "Creating VPC ..."
aws_response=$(aws ec2 create-vpc --cidr-block "$vpcCidrBlock" --amazon-provided-ipv6-cidr-block --output json)
# Capture the VPC ID in a variable
vpcId=$(echo -e "$aws_response" | /usr/bin/jq '.Vpc.VpcId' | tr -d '"')
echo "VPC ID ... $vpcId"
# Capture the VPC's IPv6 CIDR
#vpcV6CIDR=$(echo -e "$aws_response" | /usr/bin/jq '.Vpc.Ipv6CidrBlockAssociationSet[0].Ipv6CidrBlock' | tr -d '"')
vpcV6CIDR=$(aws ec2 describe-vpcs --query "Vpcs[?VpcId == '$vpcId'].Ipv6CidrBlockAssociationSet[0].Ipv6CidrBlock" --output text)
echo "VPC IPv6 CIDR ... $vpcV6CIDR"
# Enable DNS for the VPC
modify_response=$(aws ec2 modify-vpc-attribute --vpc-id "$vpcId" --enable-dns-support "{\"Value\":true}")
modify_response=$(aws ec2 modify-vpc-attribute --vpc-id "$vpcId" --enable-dns-hostnames "{\"Value\":true}")
# Give the VPC a Name tag
aws ec2 create-tags --resources "$vpcId" --tags Key=Name,Value="$vpcName"
# Describe the VPC
echo "VPC Info ..."
aws ec2 describe-vpcs --vpc-id "$vpcId" --output text

# Determine the subnet's /64s from the VPC's /56
echo "IPv6 Prefix ..."
[[ "$vpcV6CIDR" =~ ^([^-]+)00::(.*)$ ]] && v6prefix="${BASH_REMATCH[1]}"
echo $v6prefix

# Create IGW for IPv4 and attach it to VPC and create default route table for VPC
echo "Creating IGW ..."
gateway_response=$(aws ec2 create-internet-gateway --output json)
gatewayId=$(echo -e "$gateway_response" |  /usr/bin/jq '.InternetGateway.InternetGatewayId' | tr -d '"')
# Give the IGW a Name tag
aws ec2 create-tags --resources "$gatewayId" --tags Key=Name,Value="$gatewayName"
# Associate the IGW to the VPC
attach_response=$(aws ec2 attach-internet-gateway --internet-gateway-id "$gatewayId" --vpc-id "$vpcId")
# Describe the IGW
echo "IGW Info ..."
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values="$vpcId"" --output text

# Create EOIGW for IPv6
echo "Creating EOIGW ..."
EOIgateway_response=$(aws ec2 create-egress-only-internet-gateway --vpc-id "$vpcId" --output json)
EOIgatewayId=$(echo -e "$EOIgateway_response" |  /usr/bin/jq '.EgressOnlyInternetGateway.EgressOnlyInternetGatewayId' | tr -d '"')
# Describe the EOIGW
echo "EOIGW Info ..."
aws ec2 describe-egress-only-internet-gateways --egress-only-internet-gateway-ids="$EOIgatewayId" --output text

# Create 2 Public subnets and add IPv6 CIDR blocks to the subnets in the VPC
echo "Creating Public Subnets ..."
subnet_response1=$(aws ec2 create-subnet --cidr-block "$subNetCidrBlock1" --ipv6-cidr-block "$v6prefix"10::/64 \
 --availability-zone "$availabilityZone1" --vpc-id "$vpcId"  --output json)
PublicSubnetId1=$(echo -e "$subnet_response1" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo "Public Subnet ID 1 ... $PublicSubnetId1"
subnet_response2=$(aws ec2 create-subnet --cidr-block "$subNetCidrBlock2" --ipv6-cidr-block "$v6prefix"20::/64 \
 --availability-zone "$availabilityZone2" --vpc-id "$vpcId"  --output json)
PublicSubnetId2=$(echo -e "$subnet_response2" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo "Public Subnet ID 2 ... $PublicSubnetId2"
# Give the subnets Name tags
aws ec2 create-tags --resources "$PublicSubnetId1" --tags Key=Name,Value="$subnetName1"
aws ec2 create-tags --resources "$PublicSubnetId2" --tags Key=Name,Value="$subnetName2"
aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subnetName1" --output text | awk '{print $9}' | grep subnet
aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subnetName2" --output text | awk '{print $9}' | grep subnet
# Enable public IPv4s on public subnets
modify_response=$(aws ec2 modify-subnet-attribute --subnet-id "$PublicSubnetId1" --map-public-ip-on-launch)
modify_response=$(aws ec2 modify-subnet-attribute --subnet-id "$PublicSubnetId2" --map-public-ip-on-launch)
# Assign IPv6 address on creation of EC2 instances
modify_response=$(aws ec2 modify-subnet-attribute --subnet-id "$PublicSubnetId1" --assign-ipv6-address-on-creation)
modify_response=$(aws ec2 modify-subnet-attribute --subnet-id "$PublicSubnetId2" --assign-ipv6-address-on-creation)
# Describe the Subnets
echo "Public Subnet Info ..."
aws ec2 describe-subnets --filters "Name=tag:Name,Values="$subnetName1"" --output text
aws ec2 describe-subnets --filters "Name=tag:Name,Values="$subnetName2"" --output text

# Create a Public Route Table for this VPC Subnets
echo "Creating Public Route Table ..."
route_table_response1=$(aws ec2 create-route-table --vpc-id "$vpcId" --output json)
routeTableId1=$(echo -e "$route_table_response1" | /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
echo "Public Route Table ID ... $routeTableId1"
# Give the Public route table a Name tag
aws ec2 create-tags --resources "$routeTableId1" --tags Key=Name,Value="$routeTablePublicName"
# Add IPv4 default route for the internet gateway
route_responsev4=$(aws ec2 create-route --route-table-id "$routeTableId1" --destination-cidr-block 0.0.0.0/0 --gateway-id "$gatewayId")
# Add IPv6 default route to IGW - for public subnet
route_responsev6=$(aws ec2 create-route --route-table-id "$routeTableId1" --destination-ipv6-cidr-block ::/0 --gateway-id "$gatewayId")
# Associate Public Route Table to public subnets
associate_response1=$(aws ec2 associate-route-table --subnet-id "$PublicSubnetId1" --route-table-id "$routeTableId1")
associate_response1=$(aws ec2 associate-route-table --subnet-id "$PublicSubnetId2" --route-table-id "$routeTableId1")
# Show the route table
echo "Public Route Table Info ..."
aws ec2 describe-route-tables --route-table-id "$routeTableId1"

# Create 2 Private subnets and add IPv6 CIDR blocks to the subnets in the VPC
echo "Creating Private Subnets ..."
subnet_response3=$(aws ec2 create-subnet --cidr-block "$subNetCidrBlock3" --ipv6-cidr-block "$v6prefix"30::/64 \
 --availability-zone "$availabilityZone1" --vpc-id "$vpcId"  --output json)
PrivateSubnetId1=$(echo -e "$subnet_response3" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo "Private Subnet ID 1 ... $PrivateSubnetId1"
subnet_response4=$(aws ec2 create-subnet --cidr-block "$subNetCidrBlock4" --ipv6-cidr-block "$v6prefix"40::/64 \
 --availability-zone "$availabilityZone2" --vpc-id "$vpcId"  --output json)
PrivateSubnetId2=$(echo -e "$subnet_response4" | /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo "Private Subnet ID 2 ... $PrivateSubnetId2"
# Give the subnets Name tags
aws ec2 create-tags --resources "$PrivateSubnetId1" --tags Key=Name,Value="$subnetName3"
aws ec2 create-tags --resources "$PrivateSubnetId2" --tags Key=Name,Value="$subnetName4"
aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subnetName3" --output text | awk '{print $9}' | grep subnet
aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subnetName4" --output text | awk '{print $9}' | grep subnet
# Assign IPv6 address on creation of EC2 instances
modify_response=$(aws ec2 modify-subnet-attribute --subnet-id "$PrivateSubnetId1" --assign-ipv6-address-on-creation)
modify_response=$(aws ec2 modify-subnet-attribute --subnet-id "$PrivateSubnetId2" --assign-ipv6-address-on-creation)
# Describe the Subnets
echo "Private Subnet Info ..."
aws ec2 describe-subnets --filters "Name=tag:Name,Values="$subnetName3"" --output text
aws ec2 describe-subnets --filters "Name=tag:Name,Values="$subnetName4"" --output text

# Create a Private Route Table 1 for this VPC's IPv6 Subnets
echo "Creating Private Route Table 1  ..."
route_table_response2=$(aws ec2 create-route-table --vpc-id "$vpcId" --output json)
routeTableId2=$(echo -e "$route_table_response2" | /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
echo "Private Route Table ID 1 ... $routeTableId2"
# Give the Private Route Table 1 a Name tag
aws ec2 create-tags --resources "$routeTableId2" --tags Key=Name,Value="$routeTablePrivateName1"
# Add IPv6 default route to EOIGW - for private subnet
route_responsev6=$(aws ec2 create-route --route-table-id "$routeTableId2" --destination-ipv6-cidr-block ::/0 --gateway-id "$EOIgatewayId")
# Associate Private Route Table to private subnet 1
associate_response2=$(aws ec2 associate-route-table --subnet-id "$PrivateSubnetId1" --route-table-id "$routeTableId2")
# Show the route table
echo "Private Route Table 1 Info ..."
aws ec2 describe-route-tables --route-table-id "$routeTableId2"

# Create a Private Route Table 2 for this VPC's IPv6 Subnets
echo "Creating Private Route Table 2  ..."
route_table_response3=$(aws ec2 create-route-table --vpc-id "$vpcId" --output json)
routeTableId3=$(echo -e "$route_table_response3" | /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
echo "Private Route Table ID 2 ... $routeTableId3"
# Give the Private Route Table 2 a Name tag
aws ec2 create-tags --resources "$routeTableId3" --tags Key=Name,Value="$routeTablePrivateName2"
# Add IPv6 default route to EOIGW - for private subnet
route_responsev6=$(aws ec2 create-route --route-table-id "$routeTableId3" --destination-ipv6-cidr-block ::/0 --gateway-id "$EOIgatewayId")
# Associate Private Route Table to private subnet 2
associate_response3=$(aws ec2 associate-route-table --subnet-id "$PrivateSubnetId2" --route-table-id "$routeTableId3")
# Show the route table
echo "Private Route Table 2 Info ..."
aws ec2 describe-route-tables --route-table-id "$routeTableId3"

# Create IPv4 Default Routes for Private Route Tables
# Create EIPs for NAT Gateways
echo "Creating NAT Gateways ..."
eip1=$(aws ec2 allocate-address --domain vpc --output json)
eip2=$(aws ec2 allocate-address --domain vpc --output json)
eip1Id=$(echo -e "$eip1" | /usr/bin/jq '.AllocationId' | tr -d '"')
eip2Id=$(echo -e "$eip2" | /usr/bin/jq '.AllocationId' | tr -d '"')
# Create NAT Gateway 1
natgw1_response=$(aws ec2 create-nat-gateway --allocation-id "$eip1Id" --subnet-id "$PrivateSubnetId1" --output json)
natgw1Id=$(echo -e "$natgw1_response" | /usr/bin/jq '.NatGateway.NatGatewayId' | tr -d '"')
echo "NAT Gateway ID 1 ... $natgw1Id"
# Create NAT Gateway 2
natgw2_response=$(aws ec2 create-nat-gateway --allocation-id "$eip2Id" --subnet-id "$PrivateSubnetId2" --output json)
natgw2Id=$(echo -e "$natgw2_response" | /usr/bin/jq '.NatGateway.NatGatewayId' | tr -d '"')
echo "NAT Gateway ID 2 ... $natgw2Id"
echo "Waiting for NAT Gateways to be available ..."
# Wait for NAT Gateway 1 to be ready (State = Available)
aws ec2 wait nat-gateway-available --nat-gateway-ids="$natgw1Id" 
# Describe NAT Gateway 1
echo "NAT Gateway 1 Info ..."
aws ec2 describe-nat-gateways --nat-gateway-ids="$natgw1Id" --output text
# Add IPv4 default route for the NAT gateway 1
route_responsev4=$(aws ec2 create-route --route-table-id "$routeTableId2" --destination-cidr-block 0.0.0.0/0 --gateway-id "$natgw1Id")
# Wait for NAT Gateway 2 to be ready (State = Available)
aws ec2 wait nat-gateway-available --nat-gateway-ids="$natgw2Id"
# Describe NAT Gateway 2
echo "NAT Gateway 2 Info ..."
aws ec2 describe-nat-gateways --nat-gateway-ids="$natgw2Id" --output text
# Add IPv4 default route for the NAT gateway 2
route_responsev4=$(aws ec2 create-route --route-table-id "$routeTableId3" --destination-cidr-block 0.0.0.0/0 --gateway-id "$natgw2Id")

# Ending Time
echo "Ending script at time"; date '+%H:%M:%S'
echo "End of Script"