CM MD-to-QM project directory contents
please keep this list updated if you add new stuff!

1-array: 				template slurm script for initialopt job arrays
1-array-irc1: 				template slurm script for irc1 and irc2 job arrays
1-array-tsconstrained: 			template slurm script for tsconstrained job arrays
1-array-tsopt: 				template slurm script for tsopt job arrays
1-checkjobs: 				template slurm script for running check_cm_jobs "asarray"
1-collectresults: 			slurm script for recurring results collection
1-compress: 				slurm script for running directory cleanup/file compression
align_TSA_and_replace.py: 		fits ligand from existing TS structure into initialopt to create tsguess.pdb
checknumber.sh				counts total number of done jobs from cm-md-status.py outputs
check_cm_jobs.sh: 			checks status of jobs
check_new_jobs.sh: 			(OBSOLETE) checks status of initialopt jobs
cm-md-status.py: 			tabulates lists created by check_cm_jobs.sh
cmsetup-direct-tsopt.sh: 		sets up direct tsopt calcs starting from tsguess structure
cmsetup-ircs.sh: 			sets up irc calcs from completed tsopts
cmsetup-new-tsguess-from-xtb.sh: 	sets up tsconstrained calcs with new tsguess structure made from xtb tsopts
cmsetup-tsconstrained.sh: 		sets up tsconstrained calcs from completed initialopts
cmsetup-tsopt.sh: 			sets up tsopt calcs from completed tsconstraineds
cm-tsguess-orcaxtb-manualTS.sh: 	creates tsguess and tsconstrained inp with align_TSA_and_replace.py and write_input.py (accepts arg for alternative TS to fit)
cm-tsguess-orcaxtb.sh: 			creates tsguess and tsconstrained inp with align_TSA_and_replace.py and write_input.py (always uses Atsu's old DFT/xtal TS)
collect_cm_results.py: 			collects results for completed models
copy-over-done-models.sh: 		copies over files for models Domi has already done so that calcs aren't repeated
count_tsopt_types.sh: 			counts how many tsopts have been successfully obtained with each approach and how many have been excluded
f00001-A128-ts-opt.pdb: 		xtb optimised TS structure used for new ts guesses of A models
f00001-B256-ts-opt.pdb: 		xtb optimised TS structure used for new ts guesses of B models
f00001-C384-ts-opt.pdb: 		xtb optimised TS structure used for new ts guesses of C models
fix-failed-directopts.sh: 		(TEMPORARY) restarts direct tsopts that were set up incorrectly
get_fg_frames.py: 			extracts list of frames given functional group has contacts in from batch RIN output
orca-extract-final-geom.sh: 		extracts optimised geometry from orca output file (if orca.xyz not recovered/recoverable)
orcaxtb_intmp.txt: 			input template for preparing orca xtb calcs with write_input.py
plot_CM_results.ipynb: 			jupyter notebook for looking at own models' data, contains structure/energy checks 
redo-freq.sh: 				restart freqcrash jobs
redo-opt.sh: 				restart maxcyc/optcrash/orcaerror/extraimagmodes/etc jobs
resize-chunks.py: 			(OBSOLETE) regroups models into bigger fxxxxx-fxxxxx directories
restart-inp-exists.sh: 			prepares new 1-array files for "inp exists" jobs


note that there are xtal- and gaussian-compatible equivalents of the tsguess creation/tsconstrained input setup scripts in ../dwappett/ if needed
 
