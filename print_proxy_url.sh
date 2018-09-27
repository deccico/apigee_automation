#!/bin/bash -e  
set -o nounset

echo ----------------------------------
if [ "${APIGEE_ENV}" = 'prod' ]; then
  ENV=
else
  ENV="-${APIGEE_ENV}"
fi

echo "You can access your new api here: https://connect$ENV.service.nsw.gov.au/$API_NAME"

