#!/bin/bash -e  
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"                      
echo "Changing current directory to $DIR"                                               
cd $DIR                                                                                 
                                                                                        
echo 'Apigee proxy generation'                                                          
./proxy_gen.sh $API_NAME $API_TARGET_URL $API_NAME                                      
                                                                                        
echo 'Setup Apigee proxy policies'                                                      
python police.py $API_NAME/apiproxy/ $API_NAME                                          
echo 'Apigee proxy deploy'                                                              
./proxy_deploy.sh $API_NAME                                     
