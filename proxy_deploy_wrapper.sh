#!/bin/bash -e
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BASE_API_PATH=$1

#deciding proxy environment
branch=${2}

if [ -z ${APIGEE_SEAMLESS_DEPLOYMENT+x} ]; then
    seamless_deployment=""
else
    seamless_deployment="-s"
fi

files=($(git diff-tree --no-commit-id --name-only -r HEAD))
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

for proxy in $proxies;
do
    echo Deploying $proxy on directory $BASE_API_PATH/$proxy to $branch on $APIGEE_URL using $APIGEE_USER and $APIGEE_ORG
    $DIR/deploy.py -n $proxy -u $APIGEE_USER:$APIGEE_PASSWORD -o $APIGEE_ORG -h $APIGEE_URL -e $branch -p / -d $BASE_API_PATH/$proxy $seamless_deployment
done
