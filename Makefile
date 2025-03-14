USE_CASE ?= miwi_private_api

setup:
	@export USE_CASE=$(USE_CASE) && scripts/setup.sh

setup-destroy:
	@export USE_CASE=$(USE_CASE) && export ACTION=destroy && scripts/setup.sh

install:
	@cd scripts/clusters && ./$(USE_CASE).sh
