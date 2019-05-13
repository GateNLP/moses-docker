# moses-docker
An Ubuntu 18.10-based dockerfile for running [Moses](http://www.statmt.org/moses)

To create the image:

    $ git clone https://github.com/adam-funk/moses-docker.git
    $ cd moses-docker
    $ docker build -t moses .

To download the training and tuning data (you only need to do this once; keep the `moses-data` volume for subsequent training runs):

    $ docker volume create moses-data
    $ docker run --mount type=volume,src=moses-data,dst=/data/corpora -t -i moses
    # ./download.sh

To train a model (final output is based on `/data/models/mert-work/moses-ini`, which points to other data files):
   
    $ docker volume create moses-ru-en
    $ docker run --mount type=volume,src=moses-data,dst=/data/corpora --mount type=volume,src=moses-ru-en,dst=/data/model --rm -t -i moses
    # ./train_ru_en.sh

    $ docker volume create moses-de-en
    $ docker run --mount type=volume,src=moses-data,dst=/data/corpora --mount type=volume,src=moses-de-en,dst=/data/model --rm -t -i moses
    # ./train_de_en.sh

To run the service and publish it on port 9000 (you can change that value):

    $ docker run --mount type=volume,src=moses-ru-en,dst=/data/model -p 9000:8080 -t -i moses
    # ./server.sh

# Notes

- internal ports: 8080 for moses itself, 8081 for the bottle wrapper

- It takes quite a bit of memory to build cmph, giza, and moses: better to build the image on the server than on a laptop.

- No longer compiling boost (the Ubuntu 18.10 package is recent enough).

- You can create the `moses-data` volume and download the data once, keeping the volume for re-use with different language combinations.

- Training requires the `moses-data` volume and another volume to build the models in.

- Running the service requires only the volume with the trained models.

- The service runs on port 8080 inside the container and you can publish it to any port.

# Acknowledgements

This work is funded by the European Union's Horizon 2020 research and innovation programme under the
[SoBigData](http://sobigdata.eu/) project (grant agreement 654024) and the
[European Language Grid](https://www.european-language-grid.eu/) project (grant agreement 825627).

The Dockerfile in this repository is forked from
[skurik's original version](https://github.com/skurik/moses-docker) which does not specify a license.

The corpora used in the automatic download and training scripts are linked from the
[Moses documentation](http://www.statmt.org/moses/?n=Moses.LinksToCorpora) and
[ACL 2013 translation task](http://www.statmt.org/wmt13/translation-task.html).
We make no claims about copyright issues or licensing for them.

The training and server scripts provided are based on the
[Moses baseline](http://www.statmt.org/moses/?n=Moses.Baseline) and
[Moses as a Service](http://www.statmt.org/moses/?n=Advanced.Moses) documentation.

# WIP/TODO

- Wrapper around XML-RPC to provide a simpler REST API

- Fix the entrypoint system and make readable log files
