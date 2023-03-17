#!/bin/bash -l
################################################################################
#                               Slurm env setup                                #

#   Set number of cores
#SBATCH -c 2

#   Set RAM per core (disabled for now)
#SBATCH --mem-per-cpu=6G

#   Set mail preferences (NONE, BEGIN, END, FAIL, REQUEUE, ALL)
#SBATCH --mail-type=ALL

#   Set queue in which to submit: defq bigmem short power
#SBATCH -p bigmem

#   Set wall clock time
#SBATCH -t 0-6:00:00

#   Set job name
#SBATCH --job-name Genome-indexing

#                                                                              #
################################################################################

################################################################################
#                                   Utilities                                  #

#   Load Rocket modules
module load \
    picard \
    SAMtools \
    BWA \
    minimap2
#    GATK/4.1.3.0-GCCcore-8.3.0-Java-9.0.4-OpenJDK \

#   Set up error checking
# Stop on any error
set -e
# Stop on an error inside a pipeline
set -o pipefail
# Throw an error on calling an unassigned variable
set -u

#   Define time converter from seconds to h:m:s
convertsecs() {
    ((h=${1}/3600))
    ((m=(${1}%3600)/60))
    ((s=${1}%60))
    printf "%02d:%02d:%02d\n" $h $m $s
}

#                                                                              #
################################################################################

#   Idiotproofing
if [ $# -eq 0 ]
  then
    echo "Error: No genome supplied in \$1."
fi

#   Global Variables
genome=$1
realstarttime=$SECONDS

#   Logging
echo "===================================================="
echo "Host: "`hostname`
echo "Genome file: $genome"

################################################################################
#   BWA indexing
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Starting BWA index"
echo "-------------------------"

bwa index $genome

dur=($SECONDS - $realstarttime)
dur=$(convertsecs $dur)
echo "-------------------------"
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Finished BWA index. Duration: $dur"

################################################################################
#   SAMtools indexing
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Starting SAMtools index"
echo "-------------------------"

samtools faidx $genome

dur=($SECONDS - $realstarttime)
dur=$(convertsecs $dur)
echo "-------------------------"
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Finished SAMtools index. " \
    "Duration: $dur"

################################################################################
#   Picard dictionary creation for Picard Tools and GATK
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Starting Picard index"
echo "-------------------------"

java -jar $EBROOTPICARD/picard.jar CreateSequenceDictionary \
    R=$genome \
    O=$(perl -p -e 's/\.fa.*?$|\.fasta.*?$/\.dict/' <<< $genome)

echo "-------------------------"
dur=($SECONDS - $realstarttime)
dur=$(convertsecs $dur)
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Finished Picard index. " \
    "Duration: $dur"

################################################################################
#   Bedtools
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Starting bedtools genome generation"
echo "-------------------------"

cut -f 1,2 ${genome}.fai > ${genome}.genome

echo "-------------------------"
dur=($SECONDS - $realstarttime)
dur=$(convertsecs $dur)
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Finished bedtools genome generation. " \
    "Duration: $dur"

################################################################################
#   Generate BLAT database for searching
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Starting bedtools genome generation"
echo "-------------------------"

wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit
chmod 700 faToTwoBit
./faToTwoBit $genome ${genome}.2bit

echo "-------------------------"
dur=($SECONDS - $realstarttime)
dur=$(convertsecs $dur)
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Finished bedtools genome generation. " \
    "Duration: $dur"

################################################################################
#   Minimap2 on default parameters
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Starting Minimap2 indexing"
echo "-------------------------"

minimap2 -d ${genome}.default.mmi $genome

echo "-------------------------"
dur=($SECONDS - $realstarttime)
dur=$(convertsecs $dur)
echo "$SLURM_JOBID [`date +%Y%m%d_%H%M%S`] Finished Minimap2 indexing. " \
    "Duration: $dur"

