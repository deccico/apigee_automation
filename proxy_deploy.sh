#!/bin/bash -e
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR
source ./setenv.sh


#echo "directory name for sample proxy to be deployed
proxy=$1
directory=${2:-$proxy}
environment=${3:-$env}
password=$APIGEE_PASSWORD

echo Deploying $proxy on directory $directory to $environment on $url using $APIGEE_USER and $APIGEE_ORG

./deploy.py -n $proxy -u $APIGEE_USER:$APIGEE_PASSWORD -o $APIGEE_ORG -h $url -e $environment -p / -d $directory -h $url


