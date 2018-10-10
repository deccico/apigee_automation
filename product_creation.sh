#!/usr/bin/env bash

USAGE="Usage: product_creation.sh --file=name --APIGEE_USER=username --APIGEE_PASSWORD=password --APIGEE_ORG=organization --APIGEE_URL=url"

for i in "$@"
do
case ${i} in
    -f=*|--file=*)
    file="${i#*=}"
    shift
    ;;
    --APIGEE_USER=*)
    APIGEE_USER="${i#*=}"
    shift
    ;;
    --APIGEE_PASSWORD=*)
    APIGEE_PASSWORD="${i#*=}"
    shift
    ;;
    --APIGEE_ORG=*)
    APIGEE_ORG="${i#*=}"
    shift
    ;;
     --APIGEE_URL=*)
    APIGEE_URL="${i#*=}"
    shift
    ;;
esac
done

if [ -z ${file+x} ]  || [ -z ${APIGEE_USER+x} ]  || [ -z ${APIGEE_PASSWORD+x} ] || [ -z ${APIGEE_ORG+x} ] || [ -z ${APIGEE_URL+x} ]; then
    echo ${USAGE}
    exit 1
fi

if [ ! -f ${file} ]; then
    echo "${file} not exist"
    exit 1
fi

product=$(cat ${file} | jq -r ".name")

if [ ${product} = "null" ]; then
    echo "Invalid product name"
    exit 1
fi

statusCode="$(curl -Is -o /dev/null -w %{http_code} ${APIGEE_URL}/v1/organizations/${APIGEE_ORG}/apiproducts/${product} -u ${APIGEE_USER}:${APIGEE_PASSWORD})"

if [[ ${statusCode} = "404" ]]; then
    echo "Product ${product} does not exist. Creating it.."
    curl -s -X POST -H "Content-type:application/json" -d @${file} ${APIGEE_URL}/v1/organizations/${APIGEE_ORG}/apiproducts -u ${APIGEE_USER}:${APIGEE_PASSWORD}
    echo -e "\nSuccess"
else
    echo "Product ${product} exists. Updating it.."
    curl -s -X PUT -H "Content-type:application/json" -d @${file} ${APIGEE_URL}/v1/organizations/${APIGEE_ORG}/apiproducts/${product} -u ${APIGEE_USER}:${APIGEE_PASSWORD}
    echo -e "\nSuccess"
fi