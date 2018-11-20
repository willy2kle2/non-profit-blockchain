#!/usr/bin/env bash

# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

echo Pre-requisities
echo installing jq
sudo yum -y install jq

echo Downloading and installing model file for new service
cd ~
aws s3 cp s3://taiga-beta-test/service-2.json .  
aws configure add-model --service-model file://service-2.json --service-name managedblockchain

token=$(uuidgen)
echo Creating Fabric network $NETWORKNAME
echo Executing command: aws managedblockchain create-network --region $REGION --endpoint-url $ENDPOINT \
    --client-request-token $token \
    --network-configuration "{\"Name\":\"${NETWORKNAME}\",\"Description\":\"NGO Fabric network\",\"Framework\":\"HYPERLEDGER_FABRIC\",\"FrameworkVersion\": \"${NETWORKVERSION}\"}" \
    --member-configuration "{\"Name\":\"${MEMBERNAME}\",\"Description\":\"NGO Fabric member\",\"FrameworkConfiguration\":{\"Fabric\":{\"CaAdminUsername\":\"${ADMINUSER}\",\"CaAdminPassword\":\"${ADMINPWD}\"}}}"



result=$(aws managedblockchain create-network --region $REGION --endpoint-url $ENDPOINT  \
    --client-request-token $token \
    --network-configuration "{\"Name\":\"${NETWORKNAME}\",\"Description\":\"NGO Fabric network\",\"Framework\":\"HYPERLEDGER_FABRIC\",\"FrameworkVersion\": \"${NETWORKVERSION}\"}" \
    --member-configuration "{\"Name\":\"${MEMBERNAME}\",\"Description\":\"NGO Fabric member\",\"FrameworkConfiguration\":{\"Fabric\":{\"CaAdminUsername\":\"${ADMINUSER}\",\"CaAdminPassword\":\"${ADMINPWD}\"}}}")

echo Result is: $result
networkID=$(jq -r '.NetworkId' <<< $result)
memberID=$(jq -r '.MemberId'<<< $result)
echo Network ID: $networkID
echo Member ID: $memberID

echo Waiting for network to become ACTIVE
while (true); do
    STATUS=$(aws managedblockchain get-network --endpoint-url $ENDPOINT --region $REGION --network-id $networkID --query 'Network.Status' --output text)
    if  [[ "$STATUS" == "ACTIVE" ]]; then
        echo Status of Fabric network $NETWORKNAME with ID $networkID is $STATUS
        break
    else
        echo Status of Fabric network $NETWORKNAME with ID $networkID is $STATUS. Sleeping for 30s
        sleep 30s
    fi
done

VpcEndpointServiceName=$(aws managedblockchain get-network --endpoint-url $ENDPOINT --region $REGION --network-id $networkID --query 'Network.VpcEndpointServiceName' --output text)
OrderingServiceEndpoint=$(aws managedblockchain get-network --endpoint-url $ENDPOINT --region $REGION --network-id $networkID --query 'Network.FrameworkAttributes.Fabric.OrderingServiceEndpoint' --output text)
CaEndpoint=$(aws managedblockchain get-member --endpoint-url $ENDPOINT --region $REGION --network-id $networkID --member-id $memberID --query 'NetworkMember.FrameworkAttributes.Fabric.CaEndpoint' --output text)
echo Useful information
echo
echo Network ID: $networkID
echo Member ID: $memberID
echo Ordering Service Endpoint: $OrderingServiceEndpoint
echo Vpc Endpoint Service Name: $VpcEndpointServiceName
echo CA Service Endpoint: $CaEndpoint

# Export these values
export NETWORKID=$networkID
export MEMBERID=$memberID
export ORDERINGSERVICEENDPOINT=$OrderingServiceEndpoint
export VPCENDPOINTSERVICENAME=$VpcEndpointServiceName
export CASERVICEENDPOINT=$CaEndpoint
