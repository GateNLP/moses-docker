#!/usr/bin/env python3

import requests
import fileinput
import argparse
import xmlrpc.client


oparser = argparse.ArgumentParser(description='test client for Moses',
                                  formatter_class=argparse.ArgumentDefaultsHelpFormatter)

oparser.add_argument('-x', default=False,
                     action='store_true',
                     dest='xmlrpc'
                     help='use XMLRPC')

oparser.add_argument('-p', default=8081,
                     dest='port',
                     help='port')

oparser.add_argument('-s', default='localhost',
                     dest='host',
                     help='host')

oparser.add_argument('-e', default='utf-8',
                     dest='encoding',
                     help='encoding')

oparser.add_argument('-v', default=False,
                     action='store_true',
                     dest='verbose',
                     help='verbose')

# + input files or STDIN
# + output directory or STDOUT

options = oparser.parse_args()
