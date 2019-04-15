# Version 0.0.1
FROM ubuntu:cosmic as moses-build
MAINTAINER Adam Funk "a.funk@sheffield.ac.uk"

# base tools
RUN apt update && \
    apt install -y \
    unzip build-essential wget g++ git subversion automake \
    libtool zlib1g-dev libboost-all-dev libbz2-dev liblzma-dev \
    python-dev libsoap-lite-perl libxmlrpc-core-c3-dev python3-bottle \
    libxmlrpc-c++8-dev locales google-perftools gosu

RUN mkdir -p /home/moses && locale-gen en_GB.UTF-8
ENV LANG='en_GB.UTF-8'  LANGUAGE='en_GB:en'  LC_ALL='en_GB.UTF-8'  PYTHONIOENCODING=utf-8

# Build cmph
WORKDIR /home/moses
RUN wget http://downloads.sourceforge.net/project/cmph/cmph/cmph-2.0.tar.gz
RUN tar zxvf cmph-2.0.tar.gz
WORKDIR /home/moses/cmph-2.0
RUN ./configure --prefix=/usr/local && make && make install prefix=/usr/local/cmph

# Build Moses with xmlrpc-c option (for server)
WORKDIR /home/moses
RUN git clone https://github.com/moses-smt/mosesdecoder.git
WORKDIR /home/moses/mosesdecoder
RUN ./bjam --with-boost=/usr/lib/x86_64-linux-gnu --with-cmph=/usr/local/cmph -j8  --with-xmlrpc-c=/usr
# The config adds "bin/xmlrpc-c-config" to "/usr"

# Build giza; based on instructions from <http://www.statmt.org/moses/?n=Moses.Baseline>
WORKDIR /home/moses
RUN git clone https://github.com/moses-smt/giza-pp.git
WORKDIR /home/moses/giza-pp
RUN make
WORKDIR /home/moses/mosesdecoder
RUN mkdir tools
WORKDIR /home/moses/giza-pp
RUN cp GIZA++-v2/GIZA++ GIZA++-v2/snt2cooc.out mkcls-v2/mkcls /home/moses/mosesdecoder/tools

WORKDIR /home/moses
COPY  download.sh server.sh train* server-wrapper.py  ./


FROM ubuntu:cosmic as moses
RUN apt update && \
    apt install -y \
    unzip build-essential wget g++ git subversion automake \
    libtool zlib1g-dev libboost-all-dev libbz2-dev liblzma-dev \
    python-dev libsoap-lite-perl libxmlrpc-core-c3-dev python3-bottle \
    libxmlrpc-c++8-dev locales google-perftools gosu
RUN mkdir -p /home/moses && locale-gen en_GB.UTF-8
ENV LANG='en_GB.UTF-8'  LANGUAGE='en_GB:en'  LC_ALL='en_GB.UTF-8'  PYTHONIOENCODING=utf-8

WORKDIR /home/moses
COPY --from=moses-build  /home/moses/mosesdecoder  ./
COPY  server.sh train* server-wrapper.py  ./