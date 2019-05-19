#!/usr/bin/env python3

import requests
import argparse
import xmlrpc.client
import os.path
import re
import sys


ALIGN_RE = re.compile(r'\|\d+-\d+\|')

# https://stackoverflow.com/questions/13729638/how-can-i-filter-emoji-characters-from-my-input-so-i-can-save-in-mysql-5-5/13752628
ASTRAL_RE = re.compile(u'[\U00010000-\U0010ffff]')

BAD_DELIMITERS = re.compile(r'[|_]+')


def translate(source, options):
    clean_source = clean(source)
    if options.xmlrpc:
        target = translate_rpc(clean_source, options)
    else:
        target = translate_rest(clean_source, options)
    return target


def clean(text):
    # suppress characters outside the BMP
    text1 = ASTRAL_RE.sub(' ', text)

    # https://www.mail-archive.com/moses-support@mit.edu/msg14325.html
    # Moses doesn't like square brackets
    text1 = text1.replace('[', '(').replace(']', ')')

    # «Номер 44» needs to be spaced out
    text1 = text1.replace('«', '« ').replace('»', ' »')

    # Moses doesn't like pipes & possibly underscores
    text1 = BAD_DELIMITERS.sub('*', text1)
    return text1


def translate_rpc(source, options):
    url = 'http://%s:%i/RPC2' % (options.host, options.port)
    # example "http://localhost:8080/RPC2"
    proxy = xmlrpc.client.ServerProxy(url)
    params = {"text": source,
              "align": "true",
              "report-all-factors": "true"}
    result = unmangle(proxy.translate(params)['text'])
    return result


def translate_rest(source, options):
    url = 'http://%s:i%/' % (options.host, options.port)
    response = requests.post(url, data=source)
    return response.text


def unmangle(moses_output):
    tokens = moses_output.strip().split()
    result = []
    for token in tokens:
        # ignore the alignment data
        if not ALIGN_RE.match(token):
            clean_token = token.split('|')[0]
            # This will pass already Roman strings through without error
            # result.append(transliterate.translit(clean_token, 'ru', reversed=True))
            result.append(clean_token)
    return ' '.join(result)


oparser = argparse.ArgumentParser(description='test client for Moses',
                                  formatter_class=argparse.ArgumentDefaultsHelpFormatter)

oparser.add_argument('-x', default=False,
                     action='store_true',
                     dest='xmlrpc',
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

oparser.add_argument('-o', default=None,
                     dest='output_dir',
                     help='output directory')

oparser.add_argument('-v', default=False,
                     action='store_true',
                     dest='verbose',
                     help='verbose')

oparser.add_argument(dest='input_files', metavar='FILE', nargs='*',
                     type=str,
                     help='JSON files to render')

options = oparser.parse_args()


if options.input_files:
    for input_file in options.input_files:
        print('Reading', input_file)
        with open(input_file, 'r', encoding=options.encoding, errors='ignore') as f:
            source = f.read()
            target = translate(source, options)
            if options.output_dir:
                output_path = os.path.join(options.output_dir, os.path.basename(input_file) + 'trans.txt')
                print('Writing', output_path)
                with open(output_path, 'w', encoding=options.encoding) as f:
                    f.write(target)
            else:
                print('Output:')
                print(target)

else:
    for line in sys.stdin:
        target = translate(line.rstrip(), options)
        print('Output:')
        print(target)

        
