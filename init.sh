#!/bin/bash
ENV_FILE=".env"
rm -f $ENV_FILE

TF_VAR_EMAIL_SUB=$(aws ssm get-parameter --name sub_email | jq -r '.Parameter.Value')
echo "TF_VAR_EMAIL_SUB=$TF_VAR_EMAIL_SUB" >> $ENV_FILE

TF_VAR_TOPIC_NAME="gold-scrape-topic"
echo "TF_VAR_TOPIC_NAME=$TF_VAR_TOPIC_NAME" >> $ENV_FILE


AWS_ACCOUNT=$(aws sts get-caller-identity)
TF_VAR_AWS_ACCOUNT_ID=$(echo $AWS_ACCOUNT | jq -r '.Account')
TF_VAR_AWS_ACCOUNT_NAME=$(echo $AWS_ACCOUNT | jq -r '.Arn' |  cut -d'/' -f2)
TF_VAR_REGION=$(aws configure get region)
echo "TF_VAR_AWS_ACCOUNT_ID=$TF_VAR_AWS_ACCOUNT_ID" >> $ENV_FILE
echo "TF_VAR_REGION=$TF_VAR_REGION" >> $ENV_FILE
echo "TF_VAR_AWS_ACCOUNT_NAME=$TF_VAR_AWS_ACCOUNT_NAME" >> $ENV_FILE

LATEST_IMAGE_SHA=$(aws ecr describe-images --repository-name gold-scrape --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageDigest' --output text)
TF_VAR_IMAGE_URI="${TF_VAR_AWS_ACCOUNT_ID}.dkr.ecr.${TF_VAR_REGION}.amazonaws.com/gold-scrape@${LATEST_IMAGE_SHA}"
echo "TF_VAR_IMAGE_URI=$TF_VAR_IMAGE_URI" >> $ENV_FILE

TF_BASE_PATH="infra"
echo "TF_BASE_PATH=$TF_BASE_PATH" >> $ENV_FILE