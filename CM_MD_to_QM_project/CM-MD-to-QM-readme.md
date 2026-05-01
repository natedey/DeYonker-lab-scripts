CM MD-to-QM project directory contents
please keep this list updated if you add new stuff!

FILE					TYPE		DESCRIPTION
----------				----------	------------------------------
1-array					template	slurm script for initialopt job arrays
1-array-irc1				template	slurm script for irc1 and irc2 job arrays
1-array-tsconstrained			template	slurm script for tsconstrained job arrays
1-array-tsopt				template 	slurm script for tsopt job arrays
1-checkjobs				template 	slurm script for running check_cm_jobs "asarray"
1-collectresults			check/analyse	slurm script for recurring results collection
1-compress				cleanup		slurm script for running directory cleanup/file compression
align_TSA_and_replace.py		within setup	fits ligand from existing TS structure into initialopt to create tsguess.pdb
checknumber.sh				check/analyse   counts total number of done jobs from cm-md-status.py outputs
check_cm_jobs.sh			check/analyse   checks status of jobs
cm-md-status.py				check/analyse   tabulates lists created by check_cm_jobs.sh
cmsetup-direct-tsopt.sh			set up calcs	sets up direct tsopt calcs starting from tsguess structure
cmsetup-ircs.sh				set up calcs	sets up irc calcs from completed tsopts
cmsetup-new-tsguess-from-xtb.sh		set up calcs	sets up tsconstrained calcs with new tsguess structure made from xtb tsopts
cmsetup-tsconstrained.sh		set up calcs	sets up tsconstrained calcs from completed initialopts
cmsetup-tsopt.sh			set up calcs	sets up tsopt calcs from completed tsconstraineds
cm-tsguess-orcaxtb.sh			within setup	creates tsguess.pdb and tsconstrained inp with align_TSA_and_replace.py and write_input.py (always uses Atsu's old DFT/xtal TS)
collect_cm_results.py			check/analyse   collects results for completed models
copy-over-done-models.sh		set up calcs	copies over files for models Domi has already done so that calcs aren't repeated
count_tsopt_types.sh			check/analyse   counts how many tsopts have been successfully obtained with each approach and how many have been excluded
f00001-A128-ts-opt.pdb			template	xtb optimised TS structure used for new ts guesses of A models
f00001-B256-ts-opt.pdb			template	xtb optimised TS structure used for new ts guesses of B models
f00001-C384-ts-opt.pdb			template	xtb optimised TS structure used for new ts guesses of C models
fix-failed-directopts.sh		(TEMPORARY) 	restarts direct tsopts that were set up incorrectly
get_fg_frames.py			check/analyse   extracts list of frames given functional group has contacts in from batch RIN output
orcaxtb_intmp.txt			template	input template for preparing orca xtb calcs with write_input.py
plot_CM_results.ipynb			notebook	jupyter notebook for looking at own models' data, contains structure/energy checks
redo-freq.sh				restart calcs	restart freqcrash jobs
redo-opt.sh				restart calcs	restart maxcyc/optcrash/orcaerror/extraimagmodes/etc jobs
restart-inp-exists.sh			restart calcs	prepares new 1-array files for "inp exists" jobs


script and instructions for setting up new models are in ../MD-analysis/

if you need to do calcs on X-ray crystal structure models/using Gaussian or create new ts guess for one struc using a manually specified old ts, 
there are alternative versions of align_TSA_and_replace.py and cm-tsguess-orcaxtb.sh in ../dwappett/ that can handle those



------------------------------ OBSOLETE SCRIPTS ------------------------------

left in dir for reference but not needed as is anymore

FILE			DESCRIPTION
----------		------------------------------
check_new_jobs.sh	checks status of initialopt jobs, replaced by check_cm_jobs.sh
resize-chunks.py	reorganises existing fxxxxx-fxxxxx dirs into groups of 250 models. when making new models, bigger "chunk" size should be selected from the start

