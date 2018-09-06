#! /bin/bash -ex
set -o nounset

APP=$1

SERVICE=${2:-apigee-mg}
MICRO=${3:-mg-apigee.apps.pcf-ext.testservicensw.net}
DOMAIN=${4:-apps.pcf-ext.testservicensw.net}

cf apigee-bind-mg --app $APP --service $SERVICE --apigee_org $APIGEE_ORG --apigee_env $APIGEE_ENV --micro ${MICRO} --domain $DOMAIN --action "proxy bind" --user ${APIGEE_USER} --pass ${APIGEE_PASSWORD} --protocol 'http'

