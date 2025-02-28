setup:
	@cd terraform && terraform init -upgrade && terraform apply

CLUSTER_NUMBER ?= 1
install:
	@cd scripts/clusters && ./cluster-$(CLUSTER_NUMBER).sh