#!/bin/bash

# MD-to-QM-cluster part 1: set up workdirs and RINRUS inputs
# Created by D Wappett Nov 2025
# -----------------------------
# PLEASE READ CORRESPONDING INSTRUCTIONS FILE BEFORE RUNNING THIS SCRIPT!!!
# The script MOVES files, not copies. DO NOT USE IT WITH THE ORIGINAL PDB FILES. YOU copy what you need first, then script preps that set
# -----------------------------
# Info about this script:
# Takes a directory of pdbs extracted from MD. If using individual res_atoms files, these should be present too and match pdb names
#  (like output of MD_batch_rin: each 2cht.N.pdb file has corresponding 2cht.N.res_atoms.dat for example)
# Sets up a QM workdir for each pdb and workdirs are chunked up into subsets of N frames so you can work on manageable batches sequentially
#  (this makes it easier to keep track of progress)
# Within each workdir, creates driver input file from template and then uses it to run driver. Also prepares slurm script if requested


# Define help message
Help()
{
  echo "MD to QM-cluster model preparation script"
  echo "Arguments:"
  echo "n:  break up into sections of n pdbs"
  echo "r:  rinrus driver input template (if not rinrus.inp)"
  echo "b:  use batch res atoms files instead (just changes expected file name, you need to copy over correct batch res_atoms files)"
  echo "j:  input file format for making job submission script (g16/gauxtb/orca6/orcaxtb/array)"
  echo "h:  print this information"
  echo "for more information, read corresponding md-to-qm-instructions.txt file"
}

# set defaults: put into subsets of max 100 frames, use individual res_atoms files, rinrus driver input template is rinrus.inp
n=100
resat="individual"
rinp="rinrus.inp"


job="none"

# Read input arguments
while getopts ":n:r:j:bh" option; do
  case $option in
    n)  # size of subsets of workdirs
        if [[ $OPTARG ]]; then
          n=$OPTARG
        fi
        ;;
    r)  # rinrus driver input
        if [[ $OPTARG ]]; then
          rinp=$OPTARG
        fi
        ;;
    b)  # batch res atoms file if using that
	resat="batch"
        #if [[ $OPTARG ]]; then
        #  resat=${OPTARG}
        #fi
        ;;
    j)  # 
        if [[ $OPTARG ]]; then
          job=${OPTARG}
        fi
        ;;
    h)  # display Help
        Help
        exit;;
    \?) # Invalid option
        echo "Error: Invalid option"
        exit;;
  esac
done

# starting point for subgrouping: 
# ct (count) keeps track of how many pdbs put into subset before moving to next
ct=1
# startf keeps track of number of first frame in each subset to label folder
startnum=x

# start text file which will contain list of all workdirs for part 2
#echo -n "" > workdirs.txt

for i in $(ls *.pdb); do
  ### DIR SETUP ###
  # remove .pdb ending to get base filename
  f=${i%.pdb} 
  # get just number from filename, assuming pdbs made with cpptraj keepext so names are like "[whatever].00001.pdb" 
  fnum=$(echo $f | awk -F . '{print $NF}') 
  # if this is first of new subset, set starting frame number and create directory tempdir
  if [[ "$startnum" == "x" ]]; then
    startnum=$fnum 
    mkdir tempdir
  fi
  # make workdir for frame in tempdir
  mkdir tempdir/f$fnum
  # move pdb into its workdir
  mv $i tempdir/f$fnum/
  # copy rinrus driver input into workdir
  cp $rinp tempdir/f$fnum/rinrus.inp
  # either move individual res_atoms or copy batch res_atoms to workdir, and make sure workdir rinrus.inp specifies right pdb/res_atoms file
  if [[ "$resat" == "individual" ]]; then
    mv $f.res_atoms.dat tempdir/f$fnum/
    sed -i "s/SETPDB/$i/; s/SETRESATOMS/$f.res_atoms.dat/" tempdir/f$fnum/rinrus.inp
  else
    mv batch_res_atoms.$f.dat tempdir/f$fnum/
    sed -i "s/SETPDB/$i/; s/SETRESATOMS/batch_res_atoms.$f.dat/" tempdir/f$fnum/rinrus.inp
  fi
  # log workdir in list
  echo "tempdir/f$fnum" >> workdirs.txt

  ### RUN DRIVER AND GET QM INPS READY ###
  cd tempdir/f$fnum
  # run driver
  RINRUS_driver.py
  # find name of created input file and change to 1.inp to match standard workflow
  qminp=$(ls model_*.inp)
  if grep -q "orca" rinrus.inp; then
    mv $qminp orca.inp
  else
    mv $qminp 1.inp
  fi
  # if -j arg used, then also run relevant version of gen_jobscript to make slurm submission file
  if [[ "$job" == "g16" ]]; then
    gen_jobscript_g16.sh
  elif [[ "$job" == "gau*xtb" ]]; then
    gen_jobscript_gauxtb.sh
  elif [[ "$job" == "orca6" ]]; then
    #mv 1.inp orca.inp # use orca.inp instead if it's an orca file
    gen_jobscript_orca6.sh
  elif [[ "$job" == "orcaxtb" ]]; then
    #mv 1.inp orca.inp
    cp ~/git/DeYonker-lab-scripts/1-orcaxtb 1
  fi
  cd -

  ### SUBSET CHUNKING STUFF ###
  # if we've reached max number of frames in subset, then rename dir by start/end frame numbers and reset count/startnum variables for next subset. also change dir names in workdirs list
  if [ $ct -eq $n ]; then
    mv tempdir f${startnum}-f$fnum
    sed -i "s/tempdir/f${startnum}-f$fnum/" workdirs.txt
    if [[ "$job" == "array" ]]; then
      cp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/1-array f${startnum}-f$fnum/1-array
      sed -i "s/ASTART-AEND\%4/$((10#$startnum))-$((10#$fnum))%1/" f${startnum}-f$fnum/1-array
      sed "s/job-name=ORCAJOB/job-name=ORCA-initialopt/" f${startnum}-f$fnum/1-array
    fi
    ct=1
    startnum=x
  else
    ct=$(( ct + 1 ))
  fi
done

# if subset size doesn't divide total number of pdbs equally, make sure last tempdir renamed too
if [ -d "tempdir" ]; then
  mv tempdir f${startnum}-f$fnum
  sed -i "s/tempdir/f${startnum}-f$fnum/" workdirs.txt
  if [[ "$job" == "array" ]]; then
    cp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/1-array f${startnum}-f$fnum/1-array
    sed -i "s/ASTART-AEND\%1/$((10#$startnum))-$((10#$fnum))\%1/" f${startnum}-f$fnum/1-array
  fi
fi

