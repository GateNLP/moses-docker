# Version 0.0.1
FROM gatenlp/moses-trainer as trained-de
MAINTAINER Adam Funk "a.funk@sheffield.ac.uk"

WORKDIR /home/moses
RUN    ./train_cc.sh -s de -t en


FROM ubuntu:cosmic as moses_de_en
RUN apt update && \
    apt install -y \
    unzip build-essential wget g++ git subversion automake \
    libtool zlib1g-dev libboost-all-dev libbz2-dev liblzma-dev \
    python-dev libsoap-lite-perl libxmlrpc-core-c3-dev python3-bottle \
    libxmlrpc-c++8-dev locales google-perftools gosu locales
RUN mkdir -p /home/moses/mosesdecoder /home/moses/model && locale-gen en_GB.UTF-8
ENV LANG='en_GB.UTF-8'  LANGUAGE='en_GB:en'  LC_ALL='en_GB.UTF-8'  PYTHONIOENCODING=utf-8
COPY --from=mosesbuilder  /home/moses/mosesdecoder   /home/moses/mosesdecoder/
COPY --from=mosestrainer  /home/moses/model  /home/moses/model/

# ENTRYPOINT ["/home/moses/entrypoint.sh"]

# TODO
# trained images produced by running trainer on mosestrainer with suitable
# parameters and then creating another image with the ../model copied
