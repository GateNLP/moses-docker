#!/bin/bash

# default port 8080
/home/moses/mosesdecoder/bin/moses -f /home/moses/model/working/train/model/moses.ini --server &

# wrapper port 8081
/home/moses/server-wrapper.py &

