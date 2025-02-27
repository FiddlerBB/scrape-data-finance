#!/bin/bash
ENV_FILE=".env"
rm -f $ENV_FILE

TF_VAR_EMAIL_SUB=$(aws ssm get-parameter --name sub_email | jq -r '.Parameter.Value')
echo "TF_VAR_EMAIL_SUB=$TF_VAR_EMAIL_SUB" >> $ENV_FILE

TF_VAR_TOPIC_NAME="gold-scrape-topic"
echo "TF_VAR_TOPIC_NAME=$TF_VAR_TOPIC_NAME" >> $ENV_FILE
