#!/bin/bash -e

USAGE="Usage: proxy_export.sh --proxy=name --directory=directory --force=true --APIGEE_USER=username --APIGEE_PASSWORD=password  --APIGEE_ORG=organization"

directory="./"
force=false

for i in "$@"
do
case $i in
    -p=*|--proxy=*)
    proxy="${i#*=}"
    shift
    ;;
    -d=*|--directory=*)
    directory="${i#*=}"
    shift
    ;;
    -f=*|--force=*)
    force="${i#*=}"
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
esac
done

if [ -z ${APIGEE_USER+x} ]  || [ -z ${APIGEE_PASSWORD+x} ] || [ -z ${APIGEE_ORG+x} ]; then
    echo Error, APIGEE_USER, APIGEE_PASSOWRD and APIGEE_ORG must be set.
    echo $USAGE
    exit 1
fi

proxies=()
if [ -z ${proxy+x} ]; then
    proxies+=($(find . -maxdepth 1 -mindepth 1 -type d \( ! -regex '.*/\..*' \) | sed -e "s/\.\/\(.*\)/\1/g"))
else
    proxies+=($proxy)
fi

for proxy in ${proxies[@]}; do
    echo Export $proxy bundle files
    statusCode="$(curl -Is $APIGEE_URL/v1/organizations/$APIGEE_ORG/apis/$proxy -u $APIGEE_USER:$APIGEE_PASSWORD | head -n 1)"

    if [[ $statusCode = *"HTTP/1.1 404"* ]]; then
        echo Remote proxy $proxy doesn\'t exist
    else
        curl --silent https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis/$proxy/revisions > /tmp/$proxy.revisions.json -u $APIGEE_USER:$APIGEE_PASSWORD
        revision=$(cat /tmp/$proxy.revisions.json | sed -e "s/\[.*\([0-9]\)\".*\]$/\1/g")
        echo Remote revision $revision
        curl --silent https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis/$proxy/revisions/$revision?"format=bundle" > /tmp/$proxy.zip -u $APIGEE_USER:$APIGEE_PASSWORD
        rm -fr /tmp/$proxy
        unzip -o /tmp/$proxy.zip -d /tmp/$proxy
        mkdir -p $directory
        echo Save to $directory/$proxy
        cp -fr /tmp/$proxy $directory
    fi
done


