#!/bin/bash

set -o errexit
set -o pipefail

FINAL_DIR="/data/model"
CORPORA_DIR="/data/corpora"
TESTING=0  # controls removal of intermediate directories
CORPORA_INTERNAL=0 # controls removal of corpora (subject to TESTING)

while getopts "s:t:h?xT" opt
do
    case "$opt" in
    h|\?)
        echo "OPTIONS"
        echo "-s SL  with two-letter code for source language (required)"
        echo "-t tL  with two-letter code for target language (required)"
        echo "-T     testing: do not delete intermediate files"
        echo "-x     find corpora and build models in /home/moses rather than /data subdirectories"
        exit 0
        ;;
    s)
        SOURCE=${OPTARG}
        ;;
    t)
        TARGET=${OPTARG}
        ;;
    T)
        TESTING=1
        ;;
    x)
        FINAL_DIR="/home/moses/model"
        CORPORA_DIR="/home/moses/corpora"
        CORPORA_INTERNAL=1
        ;;
    esac
done

if [[ -z ${SOURCE} ]] || [[ -z ${TARGET} ]]
then
    echo "-s and -t options are required!"
    exit 99
fi

echo "source language: ${SOURCE}"
echo "target language: ${TARGET}"


MOSES_DIR="/home/moses/mosesdecoder"
TRAINING_DIR="${CORPORA_DIR}/training"
TUNING_DIR="${CORPORA_DIR}/tuning"
WORKING_DIR="${FINAL_DIR}/working"

mkdir -p ${WORKING_DIR}
cd ${WORKING_DIR}

# Loop through the required input files and fail if missing

REQUIRED_FILES=( "${TRAINING_DIR}/commoncrawl.${SOURCE}-${TARGET}.${TARGET}"  \
                 "${TRAINING_DIR}/commoncrawl.${SOURCE}-${TARGET}.${SOURCE}"  \
                 "${TUNING_DIR}/newstest2012.${TARGET}" \
                 "${TUNING_DIR}/newstest2012.${SOURCE}" )

for FILE in "${REQUIRED_FILES[@]}"
do
    if [[ ! -f ${FILE} ]]
    then
        echo "Required input file ${FILE} is missing!"
        exit 100
    fi
done


${MOSES_DIR}/scripts/tokenizer/tokenizer.perl -l ${TARGET}  <${TRAINING_DIR}/commoncrawl.${SOURCE}-${TARGET}.${TARGET} \
                                               >commoncrawl.${SOURCE}-${TARGET}.tok.${TARGET}

${MOSES_DIR}/scripts/tokenizer/tokenizer.perl -l ${SOURCE}  <${TRAINING_DIR}/commoncrawl.${SOURCE}-${TARGET}.${SOURCE} \
                                               >commoncrawl.${SOURCE}-${TARGET}.tok.${SOURCE}

${MOSES_DIR}/scripts/recaser/train-truecaser.perl --model  truecase-model.${TARGET} --corpus commoncrawl.${SOURCE}-${TARGET}.tok.${TARGET}

${MOSES_DIR}/scripts/recaser/train-truecaser.perl --model  truecase-model.${SOURCE} --corpus commoncrawl.${SOURCE}-${TARGET}.tok.${SOURCE}

${MOSES_DIR}/scripts/recaser/truecase.perl --model truecase-model.${TARGET}   <commoncrawl.${SOURCE}-${TARGET}.tok.${TARGET}  >commoncrawl.${SOURCE}-${TARGET}.true.${TARGET}

${MOSES_DIR}/scripts/recaser/truecase.perl --model truecase-model.${SOURCE}   <commoncrawl.${SOURCE}-${TARGET}.tok.${SOURCE}  >commoncrawl.${SOURCE}-${TARGET}.true.${SOURCE}

${MOSES_DIR}/scripts/training/clean-corpus-n.perl   commoncrawl.${SOURCE}-${TARGET}.true ${SOURCE} ${TARGET} commoncrawl.${SOURCE}-${TARGET}.clean 1 80

echo "Training preparation complete!"

${MOSES_DIR}/bin/lmplz -o 3 <commoncrawl.${SOURCE}-${TARGET}.true.${TARGET}   >commoncrawl.${SOURCE}-${TARGET}.arpa.${TARGET}

${MOSES_DIR}/bin/build_binary commoncrawl.${SOURCE}-${TARGET}.arpa.${TARGET} commoncrawl.${SOURCE}-${TARGET}.blm.${TARGET}

${MOSES_DIR}/scripts/training/train-model.perl --root-dir train  \
   -corpus ${WORKING_DIR}/commoncrawl.${SOURCE}-${TARGET}.clean -f ${SOURCE} -e ${TARGET} -alignment grow-diag-final-and \
   -reordering msd-bidirectional-fe -lm 0:3:${WORKING_DIR}/commoncrawl.${SOURCE}-${TARGET}.blm.${TARGET}:8 \
   -external-bin-dir ${MOSES_DIR}/tools >& training.out

tail training.out

echo "Training complete!"

${MOSES_DIR}/scripts/tokenizer/tokenizer.perl -l ${TARGET} <${TUNING_DIR}/newstest2012.${TARGET} >newstest2012.tok.${TARGET}

${MOSES_DIR}/scripts/tokenizer/tokenizer.perl -l ${SOURCE} <${TUNING_DIR}/newstest2012.${SOURCE} >newstest2012.tok.${SOURCE}

${MOSES_DIR}/scripts/recaser/truecase.perl --model truecase-model.${TARGET}   <newstest2012.tok.${TARGET} >newstest2012.true.${TARGET}

${MOSES_DIR}/scripts/recaser/truecase.perl --model truecase-model.${SOURCE}   <newstest2012.tok.${SOURCE} >newstest2012.true.${SOURCE}

echo "Tuning preparation complete!"

cd ${FINAL_DIR}

${MOSES_DIR}/scripts/training/mert-moses.pl  ${WORKING_DIR}/newstest2012.true.${SOURCE}  \
   ${WORKING_DIR}/newstest2012.true.${TARGET} ${MOSES_DIR}/bin/moses  ${WORKING_DIR}/train/model/moses.ini  \
   --mertdir ${MOSES_DIR}/bin &>mert.out 

tail mert.out

echo "Tuning complete!"

if [[ ${TESTING} -eq 1 ]]
then
    echo "Not deleting intermediate files"
else
    echo "Deleting intermediate files"
    rm -fr ${WORKING_DIR}
    if [[ ${CORPORA_INTERNAL} -eq 1 ]]
    then
        echo "Deleting local corpora"
        rm -fr ${CORPORA_DIR}
    fi

fi
