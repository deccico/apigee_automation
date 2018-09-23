#!/bin/bash -e  
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"                      
echo "Changing current directory to $DIR"                                               
cd $DIR                                                                                 
                                                                                        
echo 'Validating parameters'
./validate_inputs.sh

echo 'Apigee proxy generation'                                                          
./proxy_gen.sh $API_NAME $API_TARGET_URL $API_NAME                                      
                                                                                        
echo 'Setup Apigee proxy policies'                                                      
python police.py $API_NAME/apiproxy/ $API_NAME                                          

echo 'Apigee proxy deploy'                                                              
./proxy_deploy.sh $API_NAME                                     

echo ----------------------------------
echo "Finished creating your Apigee Api Proxy $API_NAME"
if [ "${APIGEE_ENV}" = 'prod' ]; then
  ENV=
else
  ENV="-${APIGEE_ENV}"
fi

echo "You can access it here: https://connect$ENV.service.nsw.gov.au/$API_NAME"

