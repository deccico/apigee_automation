#!/bin/bash -e
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BASE_API_PATH=$2

cd $BASE_API_PATH

files=($(git show --stat --oneline HEAD | grep "|" | tr -d "[:blank:]"))
echo Find changed files:

len=${#files[@]}
proxies=()

for((i=0;i<$len;i++))
do
    file=${files[i]}
    echo "  $file"
    if [[ "$file" =~ ^api-proxies/.* ]]; then
        file=${file#*api-proxies/}
        proxies+=${file%%/*}
    fi
done

proxies=$(for i in ${proxies[@]}; do echo $i; done | sort -u)

for proxy in $proxies;
do
    echo $DIR/proxy_deploy.sh $1 $BASE_API_PATH/$proxy $3
    $DIR/proxy_deploy.sh $1 $BASE_API_PATH/$proxy $3
done
