#!/usr/bin/env sh

cd terraform
terraform init -upgrade

if [[ -z "${USE_CASE}" ]]; then
    if [[ "${ACTION}" == "destroy" ]]; then
        # destroy all use cases if one is not specified
        terraform apply -destroy
    else
        # apply all use cases if one is not specified
        terraform apply
    fi
else
    if [[ "${ACTION}" == "destroy" ]]; then
        # destroy only the specified use case if specified
        terraform apply -target=module.${USE_CASE} -destroy
    else
        # apply only the specified use case if specified
        terraform apply -target=module.${USE_CASE}
    fi
fi
