#!/bin/bash -ex

#to make mandatory the usage of argumnents
set -o nounset

API_NAME=$1
API_TARGET_URL=$2
API_BASE_PATH=$3

./proxy_gen.sh ${API_NAME} ${API_TARGET_URL} ${API_BASE_PATH}
./deploy.sh ${API_NAME}

