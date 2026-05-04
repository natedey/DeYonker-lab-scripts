# Domi Wappett's personal scripts

Scripts created 2024 - 2026
Either specific to one project or not thoroughly tested


### CM stuff not part of big MD-to-QM-cluster project
cm-constraints.sh				prints atom numbers of C1,C9,O5,C7 or in orca/gaussian format
cm-tsguess-orcaxtb-manualTS.sh			create ts guess and inp with specified model and ts pdbs
ind_vs_batch_rmsds.py				compare individual and batch models (for batch paper
tsguessinp-gaussian.sh				like cm-tsguess-orcaxtb.sh but for making gaussian inputs
tsguessinp-gauxtb.sh				like cm-tsguess-orcaxtb.sh but for making gauxtb inputs
xtal_compatible_old_align_TSA_and_replace.py	fit old ts to make ts guesses for xtal models
xtal-only-cm-tsguess-orcaxtb.sh			like cm-tsguess-orcaxtb.sh but for xtal models
xtb-modred-inp.sh				creates gauxtb tsconstrained inp for models trimmed from maximal ts 


### POSS stuff
1-orca-poss-goat				1 file set up for orca xtb goat calcs
orca-goat-template.inp				template for preparing orca goat inp files
write-poss-orca-inp.py				script to create orca goat inp files using template

### Prototypes for new RINRUS functions or things that might be generally helpful
fg_rmsd.py					get RMSDs for each individual FG between given models
qmmm_pdb_orca.py				create PDB file with QM-region flag column for ORCA QM/MM
						  using RINRUS res_N.pdb to determine what gets flagged
write_isapt_inp.py				create (F)ISAPT input file
write_isapt_seed_part_example.txt		example of how to specify contents of frags A/X for write_isapt_inp
						  actual calc example: /project/dwappett/AspDC/big-dist-ISAPT/FISAPT


### HPC setup stuff (at 4 May 2026)
bash_profile	has all my path/python path stuff
bashrc		has all my aliases/custom functions/variables for specific project dirs/etc


