#!/bin/bash -e
set -o nounset

BASE_PATH=/code/apigee_automation
IMAGE_NAME=registry.gitlab.com/snsw-int/apigee_automation
ENV_FILE=./apigee_automation-env

echo 'Setting Environment Variables'
source $ENV_FILE


echo 'Apigee proxy generation'
docker run --rm --env-file $ENV_FILE $IMAGE_NAME $BASE_PATH/apigee_proxy_gen.sh
