Apigee Automation
=================

This repository contains a set of scripts to create / update automatically api proxies on Apigee.

Entrypoint and example of usage can be found on `Jenkinsfile`


proxy_sync.sh
-----------------

The script detects changes of API directory and sync the changes to apigee edge. 
It supports 3 types of api directory. 

  1. API bundle directory.
  2. Open API without bundle directory.
  3. Open API with bundle directory.
 

usage: proxy_sync  
  - options:  
    - None, must run in apigee api folder
    
  - example:  
    - /path/to/proxy_sync.sh  
    
    
  - How it works  
    The script reads changed files from git last commit, detect which API directory changed. 
    1. For API bundle directory  
    If the API bundle doesnt exist, create the proxy, and then deploy bundle file to apigee. 
    
    2. For open API without bundle directory  
    Invoke openapi2apigee to create or update the proxies. Push created bundle file to git remote repository. 
    
    3. For open API with bundle directory  
    Invoke openapi2apigee to create or update the proxies. Update bundle file target's basepath and proxies's flow. and then deploy bundle file to apigee. 
    
    <br>
    <img src="doc/proxy_sync.png"/>
  
  - Note
    - For Open API with bundle directory. It requires: 
        1. targets/default.xml must define &lt;URL/>
        2. proxies/default.xml must define &lt;Flows/>
      
      The script requires these placeholders to replace with real API basepath and API flows.
  
    