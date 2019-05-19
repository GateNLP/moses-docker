# Version 0.0.1
FROM gatenlp/moses-trainer as training
MAINTAINER Adam Funk "a.funk@sheffield.ac.uk"

WORKDIR /home/moses
RUN    ./train_cc.sh -s fr -t en


FROM    gatenlp/moses-software
# includes /home/moses/mosesdecoder
WORKDIR /home/moses/model
COPY    --from=training  /home/moses/model  /home/moses/model/
COPY    --from=training  /home/moses/server.sh /home/moses/server-wrapper.py /home/moses/entrypoint.sh  /home/moses/

# TODO test this
# ENTRYPOINT ["/home/moses/entrypoint.sh"]
