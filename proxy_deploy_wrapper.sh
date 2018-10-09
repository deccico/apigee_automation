#!/bin/bash -ex
set -o nounset

BASE_API_PATH=$2
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
#cd $BASE_API_PATH

files=($(git show --stat --oneline HEAD | grep "|" | tr -d "[:blank:]"))
if [ -z ${CI_BUILD_REF_NAME+x} ]; then
    git_branch=`git rev-parse --abbrev-ref HEAD`
else
    git_branch=$CI_BUILD_REF_NAME
fi
export git_branch=$git_branch


export APIGEE_ENV=$git_branch
echo Find changed files:

len=${#files[@]}
for((i=0;i<$len;i++))
do
    #f=${files[i]}
    #remove the first component
    #f=${f#*/}
    #files${files[i]%%/*} 
    #files[i]=${f}%%/*}
    echo "  ${files[i]}"
    #files[i]=${files[i]%%/*}
    #todo save api-proxies/proxy
done

proxies=$(for i in ${files[@]}; do echo $i; done | sort -u)

pwd=$(pwd)

for proxy in $proxies;
do
    #todo: skip anything not in api-proxies
    if [[ ! $f = *"/api-proxies"* ]]; then
        echo "Skipping $f"
        continue
    fi
    #todo: we need to extract a/b from a/b/c/d
    export proxy=$proxy
    path="$pwd/$proxy"
    $DIR/proxy_deploy.sh $1 $BASE_API_PATH/$proxy $3
done
