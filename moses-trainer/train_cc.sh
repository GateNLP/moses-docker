#!/bin/bash

set -o errexit
set -o pipefail

DATA_DIR="/home/moses"

while getopts "s:t:h?x" opt
do
    case "$opt" in
    h|\?)
        echo "OPTIONS"
        echo "-s SL  with two-letter code for source language (required)"
        echo "-t tL  with two-letter code for target language (required)"
        echo "-x     find corpora and build models in subdirectories of /data instead of /home/moses"
        exit 0
        ;;
    s)
        SOURCE=${OPTARG}
        ;;
    t)
        TARGET=${OPTARG}
        ;;
    x)
        DATA_DIR="/data"
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

MODEL_DIR="${DATA_DIR}/model"
CORPORA_DIR="${DATA_DIR}/corpora"


MOSES_DIR="/home/moses/mosesdecoder"
TRAINING_DIR="${CORPORA_DIR}/training"
TUNING_DIR="${CORPORA_DIR}/tuning"
WORKING_DIR="${MODEL_DIR}/working"

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

date -Iseconds
echo "Begin preparation for training"

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
date -Iseconds
echo "Begin training"

${MOSES_DIR}/bin/lmplz -o 3 <commoncrawl.${SOURCE}-${TARGET}.true.${TARGET}   >commoncrawl.${SOURCE}-${TARGET}.arpa.${TARGET}

${MOSES_DIR}/bin/build_binary commoncrawl.${SOURCE}-${TARGET}.arpa.${TARGET} commoncrawl.${SOURCE}-${TARGET}.blm.${TARGET}

${MOSES_DIR}/scripts/training/train-model.perl --root-dir train  \
   -corpus ${WORKING_DIR}/commoncrawl.${SOURCE}-${TARGET}.clean -f ${SOURCE} -e ${TARGET} -alignment grow-diag-DATA-and \
   -reordering msd-bidirectional-fe -lm 0:3:${WORKING_DIR}/commoncrawl.${SOURCE}-${TARGET}.blm.${TARGET}:8 \
   -external-bin-dir ${MOSES_DIR}/tools >& training.out

tail training.out

echo "Training complete!"
date -Iseconds
echo "Begin preparation for tuning"

${MOSES_DIR}/scripts/tokenizer/tokenizer.perl -l ${TARGET} <${TUNING_DIR}/newstest2012.${TARGET} >newstest2012.tok.${TARGET}

${MOSES_DIR}/scripts/tokenizer/tokenizer.perl -l ${SOURCE} <${TUNING_DIR}/newstest2012.${SOURCE} >newstest2012.tok.${SOURCE}

${MOSES_DIR}/scripts/recaser/truecase.perl --model truecase-model.${TARGET}   <newstest2012.tok.${TARGET} >newstest2012.true.${TARGET}

${MOSES_DIR}/scripts/recaser/truecase.perl --model truecase-model.${SOURCE}   <newstest2012.tok.${SOURCE} >newstest2012.true.${SOURCE}

echo "Tuning preparation complete!"
date -Iseconds
echo "Begin tuning"

cd ${DATA_DIR}

${MOSES_DIR}/scripts/training/mert-moses.pl  ${WORKING_DIR}/newstest2012.true.${SOURCE}  \
   ${WORKING_DIR}/newstest2012.true.${TARGET} ${MOSES_DIR}/bin/moses  ${WORKING_DIR}/train/model/moses.ini  \
   --mertdir ${MOSES_DIR}/bin &>mert.out 

tail mert.out

date -Iseconds
echo "Tuning complete!"

# WIP speeding up
# /data/model/working/train# mkdir binarised-model
# /data/model/working/train# /home/moses/mosesdecoder/bin/processPhraseTableMin -in model/phrase-table.gz -nscores 4 -out binarised-model/phrase-table

# /data/model/working/train# /home/moses/mosesdecoder/bin/processLexicalTableMin -in model/reordering-table.wbe-msd-bidirectional-fe.gz -out binarised-model/reordering-table

#  ~/mosesdecoder/bin/processLexicalTableMin \
#   -in train/model/reordering-table.wbe-msd-bidirectional-fe.gz \
#   -out binarised-model/reordering-table
# see p.40 of PDF manual

# duplicate and edit moses.ini file
# no vi in image --- add vim package