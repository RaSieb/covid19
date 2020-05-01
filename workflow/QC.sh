#!/bin/bash
# By Thomas Y. Michaelsen
VERSION=0.1.0

### Description ----------------------------------------------------------------

USAGE="$(basename "$0") [-h] [-d dir -r file] 
-- COVID-19 QC script v. $VERSION:  

Arguments:
    -h  Show this help text.
    -b  What batch to do QC for.
    -r  R script to run to generate QC report.
    -t  Number of threads.

Output:
    To come.
"
### Terminal Arguments ---------------------------------------------------------

# Import user arguments
while getopts ':hb:r:t:' OPTION; do
  case $OPTION in
    h) echo "$USAGE"; exit 1;;
    b) BATCH=$OPTARG;;
    r) RMD=$OPTARG;;
    t) THREADS=$OPTARG;;
    :) printf "missing argument for -$OPTARG\n" >&2; exit 1;;
    \?) printf "invalid option for -$OPTARG\n" >&2; exit 1;;
  esac
done

# Check missing arguments
MISSING="is missing but required. Exiting."
if [ -z ${BATCH+x} ]; then echo "-b $MISSING"; exit 1; fi;
if [ -z ${RMD+x} ]; then echo "-r $MISSING"; exit 1; fi;
if [ -z ${THREADS+x} ]; then THREADS=50; fi;

### Code.----------------------------------------------------------------------

AAU_COVID19_PATH="$(dirname "$(readlink -f "$0")")"

# Setup dirs.
mkdir -p $BATCH/QC
mkdir -p $BATCH/QC/aligntree

REF=$AAU_COVID19_PATH/MN908947.3.gb

###############################################################################
# Setup data to be used in QC.
###############################################################################

# Copy over sequences.
cp $BATCH/processing/results/consensus.fasta $BATCH/QC/aligntree/sequences.fasta
#cat export/*_export/sequences.fasta > QC/aligntree/sequences.fasta

### Alignment ###
augur align \
--sequences $BATCH/QC/aligntree/sequences.fasta \
--reference-sequence $REF \
--output $BATCH/QC/aligntree/aligned.fasta \
--nthreads $THREADS &> $BATCH/QC/aligntree/log.out

### Mask bases ###
mask_sites="18529 29849 29851 29853"

python3 $AAU_COVID19_PATH/mask-alignment.py \
--alignment $BATCH/QC/aligntree/aligned.fasta \
--mask-from-beginning 130 \
--mask-from-end 50 \
--mask-sites $mask_sites \
--output $BATCH/QC/aligntree/masked.fasta
    
### Tree ###
augur tree \
--alignment $BATCH/QC/aligntree/masked.fasta \
--output $BATCH/QC/aligntree/tree_raw.nwk \
--nthreads $THREADS
  
###############################################################################
# Generate the QC report.
###############################################################################

# Fetch path lab metadata.
pth=$(grep "\-d" $BATCH/processing/log.out | sed 's/-d: //')

if [ ! -f $pth/*sequencing.csv ]; then 
  echo "ERROR: could not find lab metadata. Searched for '$pth/*sequencing.csv', but found nothing."
  exit 1
else
  labmeta=$(find $pth/*sequencing.csv)
fi

# Run .rmd script.
Rscript -e "rmarkdown::render(input='$RMD',output_file='$PWD/$BATCH/QC/$BATCH.html',knit_root_dir='$PWD',params=list(batch='$BATCH',labmeta='$labmeta'))"


