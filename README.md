# DeYonker lab scripts: new readme Sep 2025

### Using scripts

1. Clone repo on bigblue
2. Add repo to your path by adding `export PATH=$PATH:$HOME/git/DeYonker-lab-scripts` into your ~/.bash_profile
3. Then scripts can be run as `script.py [args]` or `script.sh [args]` without needing to specify this dir's location


### Please keep your useful scripts in here!

If you create scripts you use regularly or that might be useful for other people, please keep them in here.

- Create a directory for your own stuff
- Add your subdir to your path `export PATH=$PATH:$HOME/git/DeYonker-lab-scripts/[name]` into your ~/.bash_profile as well
- Keep a short readme file of what your scripts do/usage syntax (this should be in the scripts themselves too)


### Contents of this directory:

DAW 09-25: I added this list of the directory contents and started sectioning it up/adding short descriptions of what the scripts do. Please contribute where you can too!


**Setting up your hpc environment:**
- alias_bash_profile.txt
	- this is a list of useful aliases for your bash_profile


**Preparing jobs**
- gen_irc.py
	```
	usage: gen_irc.py
	prepares gaussian input files for irc1/irc2 from finished tsopt calc
	```
- xtb_gen_irc.py
	```
	usage: xtb_gen_irc.py
	same as gen_irc.py but for xtb calcs in gaussian
	```
- xtb-g16-pdbfix.py
	```
	usage: xtb-g16-pdbfix.py [pdb]
	creates 1.fix constraints file
	```
- gen_jobscript_g16.sh
	```
	usage: gen_jobscript_g16.sh
	creates 1 slurm submission script for gaussian input file with matching mem/cpu settings
	```
- gen_jobscript_orca6.sh
	```
	usage: gen_jobscript_orca6.sh [optional: orca inp file name]
	creates 1 slurm submission script for orca input file with matching mem/cpu settings
	```
- gen_jobscript_psi4.sh
	```
	usage: gen_jobscript_psi4.sh
	creates 1 slurm submission script for psi4 input file with matching cpu settings
	```
- populate-submission-scripts.sh
	```
	usage: populate-submission-scripts.sh
	adds 1 slurm submission script to any subdirs that don't have one using the gen_jobscript_[program] scripts
	```


**Managing jobs:**
- test-completion.sh
	```
	usage: test-completion.sh [dir(s) or "list" plus list file name]
	tests completion of gaussian 1.out files in current dir and its subdirs (or dirs specified in list file). files are labeled as complete/incomplete/failed
	```
- check-opt.sh
	```
	usage: check-opt.sh [file]
	extracts steps with smallest forces and lowest energy from gaussian output
	if no file specified, will extract from 1.out
	```
- propagate_fails.sh
	```
	usage: propagate_fails.sh [label]
	saves gaussian 1.inp, 1.out and 1.chk as [n]-[label]-inp, [n]-[label]-out and [n]-[label]-chk and so previous runs don't get overwritten
	increases count each time so files are kept in chronological order
	```
- propagate_orca.sh
	```
        usage: propagate_orca.sh [orca file name] [label]
        same as propagate_fails.sh but for orca jobs. saves the inp and out files and gbw/hess if present
	```


**Collecting outputs:**
- extract.sh
	```
	usage: extract.sh [warning/col/list] [list]
	extracts energies from 1.out files in dir and its subdirs
	arg "warning" - prints warnings
	arg "col" - prints in column format
	arg "list" - extracts from dirs specified in list txt file
	```


**MD stuff:**
- add_chain.py
	```
	usage: add_chain.py -list [file listing pdbs] -chain [startres/endres/chainletter ...]
	adds chain info to pdbs (for example ones created from MD runs with cpptraj)
	```


**Not yet sorted/described:**
- avg_pdbs.py
- big-mol.sh
- car_to_pdb.py
- cerius_loader.py
- cerius-xyz-gen-from-moe.sh
- combifromcontacts.py
- CombiFromContacts.py
- convert-coords.sh
- create-simspec-ir.sh
- create-simspec-nmr.sh
- create-simspec-uv.sh
- cubegen.sh
- extract-geom-input.sh
- extract-geom-output.sh
- genmodelfiles.py
- GenResAtoms.py
- gopt_etrack.py
- gopt_pdb_transfer_mod.py
- gopt_pdb_transfer.py
- gout_extract.py
- identifiles.py
- interaction-info.py
- make-msi-series.sh
- make-msi.sh
- MDarpeggioFG.py
- MDarpeggioMaxModel.py
- MDarpeggioSIFT.py
- MDarpeggioWATNetwork.py
- MDprobeRIN.py
- measure.sh
- msi
- plot.sh
- prepare-list.py
- print-error-in-output.sh
- read_gout_xtb.py
- route-input.sh
- route.sh
- runcerius.sh
- simspec-ir
- simspec-nmr
- simspec-uv
- slurm-array-molpro.sh
- submit-all.sh
- submit-new.sh
- vec_calc.py
- write-matchmodel.sh
- write-openlog-pdb.sh
- write-openlog.sh



**Use the newer RINRUS versions of these functions instead of these scripts**
- distcalc.py (closest atom-atom distances done with RINRUS dist_rank.py)
- gopt_to_pdb.py
