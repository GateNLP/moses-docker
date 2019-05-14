# Version 0.0.1
FROM gatenlp/moses-software
MAINTAINER Adam Funk "a.funk@sheffield.ac.uk"

# Image produced: gatenlp/moses-trainer, which
# contains the moses software, the CC training corpora,
# the news tuning corpora, and an empty directory for the model
# (to be built in a subsequent image).

WORKDIR /home/moses
COPY    download.sh  ./
RUN     mkdir -p /home/moses/corpora /home/moses/model
RUN     ./download.sh
COPY    server.sh  server-wrapper.py  entrypoint.sh  train_cc.sh  ./
