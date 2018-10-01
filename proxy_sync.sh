#!/usr/bin/env bash

files=($(git diff-tree --no-commit-id --name-only -r HEAD | tr '\n' ' '))
git_branch=$(git rev-parse --abbrev-ref HEAD)

if [ -z ${APIGEE_ENV+x} ]; then
    if [ "$git_branch" = "master" ]; then
        export APIGEE_ENV="prod"
    else
        export APIGEE_ENV=$git_branch
    fi
fi
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

cd /code/apigee_automation/
source ./setenv.sh

for proxy in $proxies;
do
    path="$pwd/$proxy"

    if [[ ! ( $proxy =~ ^[a-z0-9]+$ ) && ! ( $proxy =~ ^[a-z0-9]{1,4}-[a-z0-9-]+$ ) ]]; then
        echo "Invalid proxy name $proxy"
        exit 1
    fi

    if [ -f "$path/$proxy.json" ]; then
        if [ -d "$path/apiproxy" ]; then
            echo Create open API proxies
            openapi2apigee generateApi $proxy --source $path/$proxy.json --deploy --destination /tmp/ --baseuri $APIGEE_URL --organization $APIGEE_ORG --environments $APIGEE_ENV --virtualhosts default --username $APIGEE_USER --password $APIGEE_PASSWORD
            flows=$(grep -ozP '(?s)<Flows>(?:(?!Flows).).*(?:(?!Flows).)*?</Flows>' /tmp/$proxy/apiproxy/proxies/default.xml)
            flows=$(echo ${flows} | tr -d '\n' | sed -e "s|&quot;|\"|g")
            target_url=$(grep -ozP '(?s)<URL>(.*)</URL>' /tmp/$proxy/apiproxy/targets/default.xml)

            rm -fr /tmp/$proxy
            cp -r $path /tmp

            sed -i -e "s|<Flows\/>|$flows|g" /tmp/$proxy/apiproxy/proxies/default.xml
            sed -i -e "s|<URL\/>|$target_url|g" /tmp/$proxy/apiproxy/targets/default.xml

            echo "Deploy /tmp/$proxy/"
            source ./proxy_deploy.sh $proxy /tmp/$proxy/

        else
            openapi2apigee generateApi $proxy --source $path/$proxy.json --deploy --destination /tmp/$proxy --baseuri $APIGEE_URL --organization $APIGEE_ORG --environments $APIGEE_ENV --virtualhosts default --username $APIGEE_USER --password $APIGEE_PASSWORD

            cp -r /tmp/$proxy/$proxy/apiproxy $path

            # to refine the replace
            sed -i -e '/<Flows>/,/<\/Flows>/{//!d}' $path/apiproxy/proxies/default.xml
            sed -i -e "s|<Flows>|<Flows/>|g" $path/apiproxy/proxies/default.xml
            sed -i -e "s|</Flows>||g" $path/apiproxy/proxies/default.xml

            sed -i -e "s|<URL>.*<\/URL>|<URL\/>|g" $path/apiproxy/targets/default.xml

            if [ -z ${SSH_PRIVATE_KEY+x} ]; then
                echo "${SSH_PRIVATE_KEY}" > /tmp/.ssh/id_rsa
                GIT_SSH_COMMAND="ssh -i /tmp/.ssh/id_rsa"

                cd $pwd
                git config --global user.name "Jenkins Agent"
                git config --global user.email "Jenkins_Agent@localhost"
                git add $proxy
                git commit -m "adding $proxy proxy config"
                git push origin HEAD:git_branch
                cd /code/apigee_automation/
            fi
        fi
    elif  [ -d "$path" ]; then
        statusCode="$(curl -Is $APIGEE_URL/v1/organizations/$APIGEE_ORG/apis/$proxy -u $APIGEE_USER:$APIGEE_PASSWORD | head -n 1)"

        if [[ $statusCode = *"HTTP/1.1 404"* ]]; then
            echo "Create proxy $proxy"
            curl -H "Content-type:application/json" -X POST -d "{\"name\" : \"$proxy\"}"  $APIGEE_URL/v1/organizations/$APIGEE_ORG/apis/ -u $APIGEE_USER:$APIGEE_PASSWORD
        fi

        echo "Deploy $path"
        source ./proxy_deploy.sh $proxy $path
    fi
done