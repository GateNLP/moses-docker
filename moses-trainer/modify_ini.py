#!/usr/bin/env python3
import argparse
import os
import re

parser = argparse.ArgumentParser(description='rewrite moses.ini file',
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('-m', dest='mert_dir',
                    required=True,
                    help='mert-work directory')

parser.add_argument('-b', dest='bin_dir',
                    required=True,
                    help='binarised-model directory')

# oparser.add_argument(dest='input_files', metavar='FILE', nargs='*',
#                      type=str,
#                      help='JSON files to render')

options = parser.parse_args()

phrase_table = re.compile(r'(path=)(.*)/phrase-table\.gz')
reordering = re.compile(r'(path=)(.*)/reordering-table\.wbe-msd-bidirectional-fe\.gz')

source_ini = os.path.join(options.mert_dir, 'moses.ini')
target_ini = os.path.join(options.bin_dir, 'moses.ini')

with open(source_ini, 'r') as source, open(target_ini, 'w') as target:
    for line in source.readlines():
        if phrase_table.search(line):
            line = phrase_table.sub(r'\1/' + options.bin_dir + '/phrase-table.minphr')
            print('Fixed phrase table')
        elif reordering.search(line):
            line = reordering.sub(r'\1' + options.bin_dir + '/reordering-table')
            print('Fixed reordering')
        target.write(line)




