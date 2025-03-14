#!/usr/bin/env bash

set -e

ROLE_FOLDER='./roles/ideal'
ACTION="${ACTION:-create}"

for FILE in $(find $ROLE_FOLDER -type f); do
    ROLE_NAME=$(cat $FILE | jq -r '.Name')
    ROLE_ID=$(az role definition list --name "${ROLE_NAME}" | jq -r '.[].id')

    if [[ -z "${ROLE_ID}" ]]; then
        if [[ "$ACTION" == "create" ]]; then
            echo "creating role [$ROLE_NAME]..."
            az role definition create --role-definition @${FILE}
        elif [[ "$ACTION" == "delete" ]]; then
            echo "skipping deletion of role [$ROLE_NAME]...already missing..."
        fi
    else
        if [[ "$ACTION" == "create" ]]; then
            echo "skipping creation of role [$ROLE_NAME] with id [$ROLE_ID]..."
        elif [[ "$ACTION" == "delete" ]]; then
            echo "deleting role [$ROLE_NAME] with id [$ROLE_ID]..."
            az role definition delete --name "${ROLE_NAME}"
        fi
    fi
done
