#!/bin/bash

set -e

# TODO
# check options
# set $SOURCE language
# set $TARGET language
# set working directories based on an option
# test existence of input files & fail with good message if not

TRAINING_DIR="/data/corpora/training"
TUNING_DIR="/data/corpora/tuning"
MOSES_DIR="/home/moses/mosesdecoder"

FINAL_DIR="/data/model"
WORKING_DIR="/data/model/working"

mkdir -p ${WORKING_DIR}

cd ${WORKING_DIR}

${MOSES_DIR}/scripts/tokenizer/tokenizer.perl -l ${TARGET}  <${TRAINING_DIR}/commoncrawl.${SOURCE}-${TARGET}.${TARGET}  >commoncrawl.${SOURCE}-${TARGET}.tok.${TARGET}

${MOSES_DIR}/scripts/tokenizer/tokenizer.perl -l ${SOURCE}  <${TRAINING_DIR}/commoncrawl.${SOURCE}-${TARGET}.${SOURCE}  >commoncrawl.${SOURCE}-${TARGET}.tok.${SOURCE}

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

# TODO once it works
# rm -fr ${WORKING_DIR}
