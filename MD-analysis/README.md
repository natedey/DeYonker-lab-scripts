## MD simulation processing stuff

[most of this stuff created/compiled by DAW in July-Sept 2025]
these scripts set up for processing Atsu's CM long MD simulation (runs 08-25).
everything was done with slurm array jobs because processing 360000 frames takes a lot of time.


## new pdb extraction/chain adding/dir organizing scripts:

to process all in one (up to 20ns or so) use job_process_single which:
1. runs cpptraj with extract.in to get all pdbs into folder called pdbs/
2. runs rename.py to create subdirs of 1000 pdbs each (easier processing)
3. copies job_addchain to each subdir and then submits to the queue
	- job_addchain runs add_chain.py to add chain info to created pdbs

for parallel processing of longer simulations done in sections use job_process_array.
this uses a slurm array to do the steps of job_process_single on each section with one submission script.
requires individual cpptraj extract_N.in files for each section of the simulation and a file runs.txt listing all sections/runs. 
the "SBATCH --array=[1-N]" command needs to be changed to match the number of run outputs being analysed.

cpptraj extraction input files need the double autoimage/align commands to get the whole protein centered in the unit cell so stuff doesn't end up in weird places in the pdbs!!!
they're also set up to include the 600 closest waters to any of the chorismate ligands so roughly 200 in each active site. this could probably be reduced more but I wanted to be safe.


## analyzing MD data:

analyze.in is a cpptraj input file for getting rmsds, rms fluctuations etc. runs straight from the md outputs, doesn't need the extracted pdbs.

job_batchrin uses slurm array to run MD_batch_rin script. requires pdbs extracted and organised as above. currently set up to do probe and arpeggio on each active site of CM. creates tarballs of probe/arpeggio files to save space.

probe-violins.py plots stuff from the MD_batch_rin outputs made after doing job_batchrin. again currently specific to CM - creates violin plots of contact counts for each FG in each of the three active sites. 
