#!/bin/bash -e
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

files=($(git diff-tree --no-commit-id --name-only -r HEAD))

len=${#files[@]}
products=()

echo Find changed product files:
for((i=0;i<$len;i++))
do
    file=${files[i]}
    if [[ "${file}" =~ ^api-products/.* ]]; then
        file=${files[i]%%\|*}
        echo "  ${file}"
        products+=(${file})
    fi
done

products=$(for i in ${products[@]}; do echo $i; done | sort -u)

pwd=$(pwd)

for product in ${products};
do
    echo Sync product ${product}
    $DIR/product_creation.sh --file=${pwd}/${product}
done