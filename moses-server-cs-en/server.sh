#!/bin/bash

# default port 8080
/home/moses/mosesdecoder/bin/moses -f /data/model/mert-work/moses.ini --server &

# wrapper port 8081
/home/moses/server-wrapper.py &

