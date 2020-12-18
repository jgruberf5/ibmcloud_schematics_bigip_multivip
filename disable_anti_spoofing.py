#!/usr/bin/env python3

import sys
import json
import os
import urllib.request
import ssl


def allow_ip_spoofing(region, instance_id, network_interface_id):
    endpoint_url = "https://%s.iaas.cloud.ibm.com" % region
    instance_url = "%s/v1/instances/%s/network_interfaces/%s?version=2020-12-15&generation=2" % (
        endpoint_url, instance_id, network_interface_id)
    token = os.getenv('IC_IAM_TOKEN')
    data = json.dumps({"allow_ip_spoofing": True}).encode('utf8')
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        req = urllib.request.Request(instance_url, data, headers={
            'Authorization': 'Bearer %s' % token,
            'Content-Type': 'application/json'
        })
        req.get_method = lambda: "PATCH"
        res = urllib.request.urlopen(req, context=ctx)
        if res.code > 399:
            sys.stderr.write(
                'PATCH request to allow_ip_spoofing failed with result code: %d' % res.code)
            sys.exit(1)
    except Exception as ex:
        sys.stderr.write('Error allowing ip spoofing on %s - %s : %s' % (instance_url, token, ex))
        sys.exit(1)


def main():
    jsondata = json.loads(sys.stdin.read())
    if 'instance_id' not in jsondata:
        sys.stderr.write(
            'instance id required to disable anti-spoofing on network-interfaces')
        sys.exit(1)
    if 'region' not in jsondata:
        sys.stderr.write(
            'region is required to disable anti-spoofing on network-interfaces')
        sys.exit(1)
    if 'network_interface_id' not in jsondata:
        sys.stderr.write(
            'metwork_interface id is required to disable anti-spoofing on network-interfaces')
        sys.exit(1)
    allow_ip_spoofing(
        jsondata['region'], jsondata['instance_id'], jsondata['network_interface_id'])


if __name__ == '__main__':
    main()
