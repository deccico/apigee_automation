#!/bin/bash -e
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

files=($(git show --stat --oneline HEAD | grep "|" | tr -d "[:blank:]"))
echo Find changed files:

len=${#files[@]}
products=()

for((i=0;i<$len;i++))
do
    file=${files[i]}
    echo "  ${file}"
    if [[ "${file}" =~ ^api-products/.* ]]; then
        file=${files[i]%%\|*}
        products+=(${file})
    fi
done

products=$(for i in ${products[@]}; do echo $i; done | sort -u)

pwd=$(pwd)

for product in ${products};
do
    $DIR/product_creation.sh --file=${pwd}/${product}
done