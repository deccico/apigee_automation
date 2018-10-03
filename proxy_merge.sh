#!/bin/bash

USAGE="Usage: proxy_merge.sh --proxy=name --directory=directory --force=true --APIGEE_USER=username --APIGEE_PASSWORD=password  --APIGEE_ORG=organization"

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
    output="${i#*=}"
    shift
    ;;
    -f=*|--force=*)
    force="${i#*=}"
    ;;
    --APIGEE_USER=*)
    APIGEE_USER="${i#*=}"
    shift
    ;;
    --APIGEE_PASWORD=*)
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
    proxies+=($(find -maxdepth 1 -type d))
else
    proxies+=($proxy)
fi

for proxy in ${proxies[@]}; do
    echo Download $proxy bundle files

    curl https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis/$proxy/revisions/1?"format=bundle" > /tmp/$proxy.zip -u $APIGEE_USER:$APIGEE_PASSWORD
    rm -fR /tmp/$proxy
    unzip /tmp/$proxy.zip -d /tmp/$proxy

    if [ "$force" = true ] ; then
        echo Use remote bundle files
        rm -fr $directory/$proxy
        cp -fr /tmp/$proxy $directory/
    else
        local_changed_time=$(find ./ -type f -exec stat \{} --printf="%y\n" \; | sort -n -r | head -n 1)
        local_changed_time=$(date -d "$local_changed_time" +'%s%3N')

        remote_changed_time=$(grep -ozP '(?s)<LastModifiedAt>(.*)</LastModifiedAt>' /tmp/$proxy/apiproxy/$proxy.xml | sed -e 's/<[^>]*>//g')

        echo Local changed time $(date -d @$(( $(($local_changed_time)) / 1000 )))
        echo Rmote changed time $(date -d @$(( $(($remote_changed_time)) / 1000 )))

        if [ $(($remote_changed_time - $local_changed_time)) -gt 0 ]; then
            echo Use remote bundle files
            rm -fr $directory/$proxy
            cp -fr /tmp/$proxy $directory/
        else
            echo Merge local and remote bundle files
            cp -frn /tmp/$proxy $directory/
        fi
    fi
done


