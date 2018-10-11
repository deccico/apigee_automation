#!/usr/bin/env bash 
set -o nounset

export BASE=/code/apigee_automation

if [ -z ${APIGEE_SEAMLESS_DEPLOYMENT+x} ]; then
    seamless_deployment="true"
else
    seamless_deployment=""
fi
export seamless_deployment=$seamless_deployment

git branch
files=($(git show --stat --oneline HEAD | grep "|" | tr -d "[:blank:]"))
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
for((i=0;i<$len;i++))
do
    echo "  ${files[i]}"
    files[i]=${files[i]%%/*}
done

proxies=$(for i in ${files[@]}; do echo $i; done | sort -u)

pwd=$(pwd)

source $BASE/setenv.sh


for proxy in $proxies;
do
    export proxy=$proxy
    path="$pwd/$proxy"

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

            echo "Deploy /tmp/$proxy/"
            source $BASE/proxy_deploy.sh $proxy /tmp/$proxy/ $env $seamless_deployment

        else
            openapi2apigee generateApi $proxy --source $path/$proxy.json --deploy --destination /tmp/$proxy --baseuri $APIGEE_URL --organization $APIGEE_ORG --environments $APIGEE_ENV --virtualhosts default --username $APIGEE_USER --password $APIGEE_PASSWORD

            cp -r /tmp/$proxy/$proxy/apiproxy $path

            # to refine the replace
            sed -i -e '/<Flows>/,/<\/Flows>/{//!d}' $path/apiproxy/proxies/default.xml
            sed -i -e "s|<Flows>|<Flows/>|g" $path/apiproxy/proxies/default.xml
            sed -i -e "s|</Flows>||g" $path/apiproxy/proxies/default.xml

            sed -i -e "s|<URL>.*<\/URL>|<URL\/>|g" $path/apiproxy/targets/default.xml

            $BASE/persist_proxy.sh
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

        echo "Deploy $path"
        source $BASE/proxy_deploy.sh $proxy $path $env $seamless_deployment

    fi
done
