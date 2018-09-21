#!/bin/bash -ex
set -o nounset

echo 'Validating parameters'
[[ $API_NAME =~ ^[a-z0-9-]+$ ]]
[[ $API_NAME =~ ^[a-z0-9]{1,4}-[a-z0-9]+$ ]]

