# Version 0.0.1
FROM gatenlp/moses-software
MAINTAINER Adam Funk "a.funk@sheffield.ac.uk"

WORKDIR /home/moses
COPY    download.sh  train_cc.sh  ./
RUN     mkdir -p /home/moses/corpora /home/moses/model
RUN     ./download.sh

# This produces an image with the moses software, the CC training
# and news tuning corpora, and an empty directory for the model.