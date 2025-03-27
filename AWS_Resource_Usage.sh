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
aws s3 ls
#list AWS EC2
aws ec2 describe-instances

#list lamda
aws lambda list-functions
#IAM users
aws iam list-users

