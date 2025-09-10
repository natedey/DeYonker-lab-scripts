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

**It would be super helpful to have a short description of what each of these does! I (DAW) have started this off for some of the scripts I've used. Please contribute where you can! **

- alias_bash_profile.txt
	- this is a list of useful aliases for your bash_profile

- avg_pdbs.py
- big-mol.sh
- car_to_pdb.py
- cerius_loader.py
- cerius-xyz-gen-from-moe.sh
- check-opt.sh

	```
	usage: check-opt.sh [file]
	extracts steps with smallest forces and lowest energy from gaussian output
	if no file specified, will extract from 1.out
	```

- combifromcontacts.py
- CombiFromContacts.py
- convert-coords.sh
- create-simspec-ir.sh
- create-simspec-nmr.sh
- create-simspec-uv.sh
- cubegen.sh
- distcalc.py
- extract-geom-input.sh
- extract-geom-output.sh
- extract.sh

	```
	usage: extract.sh [warning/col/list] [list]
	extracts energies from 1.out files in dir and its subdirs
	arg "warning" - prints warnings
	arg "col" - prints in column format
	arg "list" - extracts from dirs specified in list txt file
	```


- gen_irc.py
- genmodelfiles.py
- GenResAtoms.py
- gopt_etrack.py
- gopt_pdb_transfer_mod.py
- gopt_pdb_transfer.py
- gopt_to_pdb.py

	- old version of the one in the rinrus github, don't use

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
- populate-submission-script-g16-b01.sh
- prepare-list.py
- print-error-in-output.sh
- propagate_fails.sh

	```
	usage: propagate_fails.sh [label]
	saves gaussian 1.inp, 1.out and 1.chk as [n]-[label]-inp, [n]-[label]-out and [n]-[label]-chk and so previous runs don't get overwritten
	increases count each time so files are kept in chronological order
	```

- propagate_orca.sh

	```
        usage: propagate_orca.sh [orca file name] [label]
        same as propagate_fail.sh but for orca jobs. saves the inp and out files and gbw/hess if present
        ```

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
- test-completion.sh

	```
	usage: test-completion.sh [dir or "list" plus list file name]
	tests completion of gaussian 1.out files in current dir and its subdirs (or dirs specified in list file). files are labeled as complete/incomplete/failed
	```

- vec_calc.py
- write-matchmodel.sh
- write-openlog-pdb.sh
- write-openlog.sh
- xtb-g16-pdbfix.py
- xtb_gen_irc.py
