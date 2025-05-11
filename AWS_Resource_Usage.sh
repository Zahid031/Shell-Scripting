#!/bin/bash
#
#version: v1
#This script will report AWS resource usage
#
##AWS S3
#AWS EC2
#AWS Lambda
#AWS IAM Users
# list s3 buckets
set -e
set -x
echo "S3 list"
aws s3 ls

#list AWS EC2
echo "ec2 list"
aws ec2 describe-instances

#list lamda
echo "Lamda list"
aws lambda list-functions
#IAM users
echo "IAM user"
aws iam list-users

