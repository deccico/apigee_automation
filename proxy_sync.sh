#!/bin/bash -e
set -o nounset

export BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

git branch
files=($(git diff-tree --no-commit-id --name-only -r HEAD))
if [ -z ${CI_BUILD_REF_NAME+x} ]; then 
    git_branch=`git rev-parse --abbrev-ref HEAD`
else
    git_branch=$CI_BUILD_REF_NAME
fi
export git_branch=$git_branch


export APIGEE_ENV=$git_branch
echo Start to sync branch $git_branch to $APIGEE_ENV environment
echo Find changed files:

len=${#files[@]}
proxies=()

for((i=0;i<$len;i++))
do
    file=${files[i]}
    echo "  $file"
    if [[ "$file" =~ ^api-proxies/.* ]]; then
        file=${file#*api-proxies/}
        proxies+=(${file%%/*})
    fi
done
proxies=$(for i in ${proxies[@]}; do echo $i; done | sort -u)

pwd=$(pwd)

source $BASE/setenv.sh

if [ -z ${APIGEE_SEAMLESS_DEPLOYMENT+x} ]; then
    seamless_deployment=""
else
    seamless_deployment="-s"
fi

for proxy in $proxies;
do
    export proxy=$proxy
    path="$pwd/api-proxies/$proxy"

    if [[ ! $path = *"/"* ]]; then
        echo "Skipping $proxy"
        continue
    fi

    if [[ ! ( $proxy =~ ^[a-z0-9]+$ ) && ! ( $proxy =~ ^[a-z0-9]{1,8}-[a-z0-9-]+$ ) ]]; then
        echo "Skipping proxy $proxy as it has an invalid name."
        continue
    fi

    if [ -f "$path/$proxy.json" ]; then
        if [ -d "$path/apiproxy" ]; then
            echo Create open API proxies
            openapi2apigee generateApi $proxy --source $path/$proxy.json --deploy --destination /tmp/$proxy --baseuri $APIGEE_URL --organization $APIGEE_ORG --environments $APIGEE_ENV --virtualhosts default --username $APIGEE_USER --password $APIGEE_PASSWORD
            flows=$(grep -ozP '(?s)<Flows>(?:(?!Flows).).*(?:(?!Flows).)*?</Flows>' /tmp/$proxy/$proxy/apiproxy/proxies/default.xml)
            flows=$(echo ${flows} | tr -d '\n' | sed -e "s|&quot;|\"|g")
            target_url=$(grep -ozP '(?s)<URL>(.*)</URL>' /tmp/$proxy/$proxy/apiproxy/targets/default.xml)

            rm -fr /tmp/$proxy
            cp -r $path /tmp

            sed -i -e "s|<Flows\/>|$flows|g" /tmp/$proxy/apiproxy/proxies/default.xml
            sed -i -e "s|<URL\/>|$target_url|g" /tmp/$proxy/apiproxy/targets/default.xml

            echo Deploying $proxy on directory /tmp/$proxy/ to $APIGEE_ENV on $APIGEE_URL using $APIGEE_USER and $APIGEE_ORG
            $BASE/deploy.py -n $proxy -u $APIGEE_USER:$APIGEE_PASSWORD -o $APIGEE_ORG -h $APIGEE_URL -e $APIGEE_ENV -p / -d /tmp/$proxy/ $seamless_deployment
        else
            openapi2apigee generateApi $proxy --source $path/$proxy.json --deploy --destination /tmp/$proxy --baseuri $APIGEE_URL --organization $APIGEE_ORG --environments $APIGEE_ENV --virtualhosts default --username $APIGEE_USER --password $APIGEE_PASSWORD

            cp -r /tmp/$proxy/$proxy/apiproxy $path

            # to refine the replace
            sed -i -e '/<Flows>/,/<\/Flows>/{//!d}' $path/apiproxy/proxies/default.xml
            sed -i -e "s|<Flows>|<Flows/>|g" $path/apiproxy/proxies/default.xml
            sed -i -e "s|</Flows>||g" $path/apiproxy/proxies/default.xml

            sed -i -e "s|<URL>.*<\/URL>|<URL\/>|g" $path/apiproxy/targets/default.xml

            $BASE/proxy_persist.sh
        fi
    elif  [ -d "$path" ]; then
        statusCode="$(curl -Is -o /dev/null -w %{http_code} $APIGEE_URL/v1/organizations/$APIGEE_ORG/apis/$proxy -u $APIGEE_USER:$APIGEE_PASSWORD)"

        if [ ${statusCode} = "404" ]; then
            echo "Proxy $proxy does not exist. Creating it.."
            echo 'Creating Apigee proxy'
            target=http://cosafinity-prod.apigee.net/v1/employees
            $BASE/proxy_gen.sh $proxy $target $proxy
            echo 'Setup Apigee proxy policies'
            python $BASE/police.py $proxy/apiproxy/ $proxy
            echo 'Adding Virtual Hosts'
            python $BASE/add_virtual_hosts.py $proxy/apiproxy/ $proxy
            $BASE/proxy_persist.sh
        else
            echo Proxy $proxy exists updating it..
        fi

        echo Deploying $proxy on directory $path to $APIGEE_ENV on $APIGEE_URL using $APIGEE_USER and $APIGEE_ORG
        $BASE/deploy.py -n $proxy -u $APIGEE_USER:$APIGEE_PASSWORD -o $APIGEE_ORG -h $APIGEE_URL -e $APIGEE_ENV -p / -d $path $seamless_deployment
    fi
done
