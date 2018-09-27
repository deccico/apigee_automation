#!/bin/bash -e
set -o nounset

source ./setenv.sh

export name=$1
export target_url=$2

# URI pattern (format '/{some_uri}', e.g. /weather, to use for inbound request pattern matching
export basepath=$3

#apigee environment
env=$APIGEE_ENV



echo Generating $name on $url using $APIGEE_USER and $APIGEE_ORG

curl -H "Content-type:application/json" -X POST -d "{\"name\" : \"$name\"}"  https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis -u $APIGEE_USER:$APIGEE_PASSWORD

# curl -H "Content-type:application/json" -X POST d'{ "name" : "$name" }' https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis -u $APIGEE_USER:$APIGEE_PASSWORD

echo "Unless you see errors, your API has been created. Calling API to verify:"

curl https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis/$name -u $APIGEE_USER:$APIGEE_PASSWORD

echo "Now setting the target URL for the backend service that you'll expose through Apigee (it doesn't have to belong to you--use http://weather.yahooapis.com if you like)"

curl -u $APIGEE_USER:$APIGEE_PASSWORD -H "Content-Type: application/json" -X POST -d  "{\"connection\" : { \"uRL\" : \"$target_url\" }, \"name\" : \"default\" }" https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis/$name/revisions/1/targets

curl -H "Content-type:application/json"  -X POST -d  "{ \"connection\" : {\"basePath\" : \"$basepath\", \"virtualHost\" : [ \"default\" ]}, \"name\" : \"default\", \"routeRule\" : [ {\"name\" : \"default\", \"targetEndpoint\" : \"default\"} ]}" https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis/$name/revisions/1/proxies -u $APIGEE_USER:$APIGEE_PASSWORD

echo Exporting API proxy to current local directory using $name on $url using $APIGEE_USER and $APIGEE_ORG

echo "Exporting API proxy to current local directory--name the ZIP file"

curl https://api.enterprise.apigee.com/v1/o/$APIGEE_ORG/apis/$name/revisions/1?"format=bundle" > $name.zip \
-u $APIGEE_USER:$APIGEE_PASSWORD

set -x
echo "Checking directory for $name.zip"

ls

echo "Removing any existing API proxies"

rm -rf ./${name}/apiproxy
rm -rf ./apiproxy

echo Unpacking

unzip $name.zip

echo "API proxy files are under ./apiproxy"

ls

echo "Creating /policies and /resources"

mkdir ./apiproxy/policies
mkdir ./apiproxy/resources

mkdir -p ./${name}
mv ./apiproxy $name 

echo "Done"

#echo "You can invoke you API proxy at http://$APIGEE_ORG-$env.apigee.net/$basepath, and it will proxy requests to $target_url"

