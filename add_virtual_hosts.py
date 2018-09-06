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

VH = "VirtualHost"

def add_virtual_hosts(directory, api_name):
    """
    file: apiproxy/proxies/default.xml
    goals: add additional virtual hosts
    change:
    <HTTPProxyConnection>
        <BasePath>my_api</BasePath>
        <Properties/>
        <VirtualHost>default</VirtualHost>
    </HTTPProxyConnection>
    for:
    <HTTPProxyConnection>
        <BasePath>my_api</BasePath>
        <Properties/>
        <VirtualHost>default</VirtualHost>
        <VirtualHost>secure</VirtualHost>
        <VirtualHost>connect</VirtualHost>
    </HTTPProxyConnection>
    """
    #parse file
    file_name = os.path.join(directory, "proxies", "default.xml")
    root = md.parse(file_name)
    #get Policies node
    node = root.getElementsByTagName(VH)
    #validate file
    if len(node) == 0:
        raise ValueError('{0} element not found in file {1}.'.format(HTTP_PROXY, file_name))
    if len(node) > 1:
        raise ValueError('I found more than one {0} element hence not changing the configuration. file {1}.'.format(VH, file_name))

    #we have one VH, we need to add two more

    #we need to add policies
    vh = root.createElement(VH)
    vh_txt = root.createTextNode("secure")
    vh.appendChild(vh_txt)
    node[0].insertBefore(vh)
    vh = root.createElement(VH)
    vh_txt = root.createTextNode("connect")
    vh.appendChild(vh_txt)
    node[0].insertBefore(vh)
    with open(file_name, 'w') as f:
        f.write(root.toxml())


def add_vh(directory, api_name):
    add_virtual_hosts(directory)
    print("finished adding virtual hosts into proxy: {0}".format(api_name))


if __name__ == "__main__":
    add_vh(sys.argv[1], sys.argv[2])


