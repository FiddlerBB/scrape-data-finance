include .env

IMAGE_NAME := gold-scrape
TAG := 1.0.0
# REPOSITORY := gold-scrape
ECR_ARN := $(TF_VAR_AWS_ACCOUNT_ID).dkr.ecr.$(TF_VAR_REGION).amazonaws.com


build:
	@echo "Building image $(IMAGE_NAME)"
# @docker build -t $(ECR_ARN)/$(IMAGE_NAME) .
	@docker build -t $(IMAGE_NAME) .

run: 
	@echo "Running image $(ECR_ARN)/$(IMAGE_NAME)"
	@docker run --rm -it -p 8083:8080 \
	$(ECR_ARN)/$(IMAGE_NAME) main.lambda_handler

push:
	@echo "Push image to ECR"

	@echo "Login into ECR"
	@aws ecr get-login-password --region $(TF_VAR_REGION) | docker login --username AWS --password-stdin $(ECR_ARN)

	@docker tag $(IMAGE_NAME):latest $(ECR_ARN)/$(IMAGE_NAME):latest
	@docker push $(ECR_ARN)/$(IMAGE_NAME)

infra-init:
	@cd $(TF_BASE_PATH) && \
		terraform init


infra-plan:
	@echo $(TF_VAR_IMAGE_URI)
	@echo $(TF_VAR_TOPIC_NAME)
	@cd $(TF_BASE_PATH) && \
	terraform plan

infra-apply:
	@cd $(TF_BASE_PATH) && \
		terraform apply

infra-destroy:
	@cd $(TF_BASE_PATH) && \
	terraform destroy