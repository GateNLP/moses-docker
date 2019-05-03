#!/bin/bash

set -o errexit
set -o pipefail

#  http://www.statmt.org/moses/?n=Moses.LinksToCorpora
#  "This page is your 'shopping list' for parallel texts."

CORPORA_DIR="/data/corpora"
while getopts "h?x" opt
do
    case "$opt" in
    h|\?)
        echo "OPTIONS"
        echo "-x     put corpora in /home/moses/corpora rather than /data/corpora"
        exit 0
        ;;
    x)
        CORPORA_DIR="/home/moses/corpora"
        ;;
    esac
done

mkdir -p "${CORPORA_DIR}/training"

cd /data/corpora
wget http://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz
wget http://www.statmt.org/wmt13/dev.tgz

cd training
tar zxf ../training-parallel-commoncrawl.tgz
cd ..
tar zxf dev.tgz
# unpacks into dev/*
mv dev tuning

# now we only need the unpacked data
rm training-parallel-commoncrawl.tgz dev.tgz
