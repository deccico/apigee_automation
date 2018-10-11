#!/bin/bash -e
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/setenv.sh


#echo "directory name for sample proxy to be deployed
proxy=${1}
directory=${2:-${proxy}}
environment=${3:-${env}}
seamless_deployment=${4:-"false"}
password=${APIGEE_PASSWORD}

if [seamless_deployment = "true" ]; then
    echo Seamless deploying ${proxy} on directory ${directory} to ${environment} on ${url} using ${APIGEE_USER} and ${APIGEE_ORG}
    ${DIR}/deploy.py -n ${proxy} -u ${APIGEE_USER}:${APIGEE_PASSWORD} -o ${APIGEE_ORG} -h ${url} -e ${environment} -p / -d ${directory} -h ${url} -s
else
    echo Deploying ${proxy} on directory ${directory} to ${environment} on ${url} using ${APIGEE_USER} and ${APIGEE_ORG}
    ${DIR}/deploy.py -n ${proxy} -u ${APIGEE_USER}:${APIGEE_PASSWORD} -o ${APIGEE_ORG} -h ${url} -e ${environment} -p / -d ${directory} -h ${url}
fi


