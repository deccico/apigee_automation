"""
This script will setup Apigee Policies given an apigee proxy bundle

notes:
the xml header gets lost but can be omitted, ref: https://stackoverflow.com/questions/3982887/how-to-add-xml-header-to-dom-object#3983027
    print("encoding: {1} standalone: {0}".format(root.standalone, root.encoding))
    root.childNodes[0].appendChild(['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'])
"""

import xml.dom.minidom as md
import os
from shutil import copyfile
import sys

POLICIES = 'Policies'
POLICY = 'Policy'
SHARED_POLICY = "shared-policy"
PROXYENDPOINT = 'ProxyEndpoint'
PREFLOW = 'PreFlow'
BASE_PATH=os.path.dirname(os.path.realpath(__file__))


def add_shared_policy(directory, api_name):
    """
    file: apiproxy/my_api.xml
    goals: add a shared policy:
    shared policy
    change:
    <Policies/>
    for:
    <Policies><Policy>shared-policy</Policy></Policies>
    """
    #parse file
    file_name = os.path.join(directory, api_name + ".xml")
    root = md.parse(file_name)
    #get Policies node
    pol = root.getElementsByTagName(POLICIES)
    #validate file
    if len(pol) == 0:
        raise ValueError('{0} element not found in file {1}.'.format(POLICIES, file_name))
    #do we need to add policies?
    if pol[0].hasChildNodes():
        raise ValueError("The current xml has policies already. Nothing to do here..")

    #we need to add policies
    policy = root.createElement(POLICY)
    policy_txt = root.createTextNode(SHARED_POLICY)
    policy.appendChild(policy_txt)
    pol[0].appendChild(policy)
    with open(file_name, 'w') as f:
        f.write(root.toxml())


def add_flow(directory):
    """
    check if <proxy_name>/apiproxy/proxies/default.xml exists
    change:

    <FaultRules/>
    <Flows/>

    for:

    <FaultRules/>
    <PreFlow name="PreFlow">
    <Request>
    <Step>
    <Name>shared-policy</Name>
    </Step>
    </Request>
    <Response/>
    </PreFlow>
    <PostFlow name="PostFlow">
    <Request/>
    <Response/>
    </PostFlow>
    <Flows/>
    """
    #file validation
    file_name = os.path.join(directory, 'proxies', "default.xml")
    root = md.parse(file_name)
    print("add_flow: analysing {0}".format(file_name))
    if not os.path.isfile(file_name):
        raise ValueError("Nothing to do here, customs rules are applied. Default proxy rules doesn't exist in {0}.".format(file_name)) 
    #do we mention shared-policy in the file?
    if SHARED_POLICY in open(file_name).read():
        raise ValueError("{0} is currently used in the file {1}. Nothing to do here.".format(SHARED_POLICY, file_name))  

    #get and validate preflownode
    pf = root.getElementsByTagName(PREFLOW)
    if len(pf) >  0:
        raise ValueError('{0} element found in file {1}. Given that there is already a preflow element, there is nothing to do here'.format(PREFLOW, file_name))

    #add our node
    proxy = root.getElementsByTagName(PROXYENDPOINT)
    pf = root.createElement(PREFLOW)
    pf.setAttribute("name", PREFLOW)
    rq = root.createElement("Request")
    step = root.createElement("Step")
    name = root.createElement("Name")
    name.appendChild(root.createTextNode(SHARED_POLICY))
    step.appendChild(name)
    rq.appendChild(step)
    pf.appendChild(rq)
    pf.appendChild(root.createElement("Response"))
    proxy[0].appendChild(pf)
    #persist xml
    with open(file_name, 'w') as f:
        f.write(root.toxml())


def create_shared_policy(directory):
    """
    if it doesn't exist, add this file:

    <proxy_name>/apiproxy/policies/shared-policy.xml

    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <FlowCallout async="false" continueOnError="false" enabled="true" name="shared-policy">
    <DisplayName>shared-policy</DisplayName>
    <FaultRules/>
    <Properties/>
    <SharedFlowBundle>shared-policy</SharedFlowBundle>
    </FlowCallout>

    """
    #file validation
    base_dir = os.path.join(directory, 'policies')
    file_name = os.path.join(base_dir, "{0}.xml".format(SHARED_POLICY))
    if not os.path.isfile(file_name):
        if not os.path.isdir(base_dir):
            os.mkdir(base_dir)
        copyfile(os.path.join(BASE_PATH, 'templates/policies/shared-policy.xml'), file_name)


def police(directory, api_name):
    add_shared_policy(directory, api_name)
    add_flow(directory)
    create_shared_policy(directory)
    print("finished adding policies into proxy: {0}".format(api_name))


if __name__ == "__main__":
    police(sys.argv[1], sys.argv[2])


