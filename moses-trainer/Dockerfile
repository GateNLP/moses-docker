# Version 0.0.1
FROM gatenlp/moses-software
MAINTAINER Adam Funk "a.funk@sheffield.ac.uk"

# Image produced: gatenlp/moses-trainer, which
# contains the moses software, the CC training corpora,
# the news tuning corpora, and an empty directory for the model
# (to be built in a subsequent image).

WORKDIR /home/moses
COPY    download.sh  server.sh  server-wrapper.sh  entrypoint.sh  train_cc.sh  ./
RUN     mkdir -p /home/moses/corpora /home/moses/model
RUN     ./download.sh

