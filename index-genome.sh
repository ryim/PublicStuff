#!/bin/bash

#   Idiotproofing
if [ $# -eq 0 ]
  then
    echo "Error: No genome supplied in \$1."
fi

#   Prep
genome=$1
echo "Genome: $genome"

#   BWA
bwa index $genome

#   Samtools
samtools faidx $genome

#   Picard and GATK
gatk CreateSequenceDictionary \
    -R $genome \
    -O $(perl -p -e 's/\.fa.*?$|\.fasta.*?$/\.dict/' <<< $genome)

#   Bedtools
cut -f 1,2 ${genome}.fai > ${genome}.genome

#   Generate BLAT database for searching
if [ ! -e faToTwoBit ]
then
#    echo 'Not there!'
    wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit
    chmod 700 faToTwoBit
fi

./faToTwoBit $genome ${genome}.2bit

#   Minimap2 on default parameters
minimap2 -d ${genome}.mmi $genome
