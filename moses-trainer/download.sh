#!/bin/bash

set -o errexit
set -o pipefail

#  http://www.statmt.org/moses/?n=Moses.LinksToCorpora
#  "This page is your 'shopping list' for parallel texts."

CORPORA_DIR="/home/moses/corpora"
while getopts "h?x" opt
do
    case "$opt" in
    h|\?)
        echo "OPTIONS"
        echo "-x     put corpora in /data/corpora instead of /home/moses/corpora"
        exit 0
        ;;
    x)
        CORPORA_DIR="/data/corpora"
        ;;
    esac
done

mkdir -p "${CORPORA_DIR}/training"

cd "${CORPORA_DIR}"
wget http://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz
wget http://www.statmt.org/wmt13/dev.tgz

cd training
tar zxf ../training-parallel-commoncrawl.tgz
# unpacks directly
cd ..
tar zxf dev.tgz
# unpacks into dev/*
mv dev tuning

# now we only need the unpacked data
rm training-parallel-commoncrawl.tgz dev.tgz
