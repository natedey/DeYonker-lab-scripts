# Domi Wappett's personal scripts

Scripts created throughout 2024 and 2025

### HPC setup stuff
- `bash_profile` has the group aliases/functions and path stuff. Similar contents to Dr D's but totally reorganised. Dirs added to path are separated out to make reordering/removing for troubleshooting much easier
- `bashrc` has my own aliases/functions. Most stuff in here is quite specific to me but is provided to give some ideas of what you might want to set up for yourself


### Modified versions of group scripts:
- `extract_DAW.sh` reformats extract.sh output
- `extract_DAW_xtb.sh` does same for xtb jobs
- `test-completion-daw.sh` simplifies input syntax for test-completion.sh


### General calculation workflow stuff
- `test-qf.sh` runs `test-completion-daw.sh` on recently finished jobs


### General output analysis stuff
- `fg_rmsd/py` gets rmsds of each functional group separately


### ORCA
- `gen_orca_jobscript.sh` creates orca slurm submission script with correct mem/cpu specs from input file
- `qmmm_pdb_orca.py` edits the occupancy column in a pdb file to flag the qm region for orca QM/MM


### FISAPT stuff
- `write_isapt_inp.py` is a janky prototype for creating isapt inputs


### Specific to chorismate mutase but can be adapted for other systems
- `align_TSA_and_replace.py` fits a ts geom into the optimised model to create a ts guess
- `tsguessinp.sh` and the xtb version run `align_TSA_and_replace.py` and then write a gaussian/gau-xtb input file with modred coordinates for a constrained ts opt
- `xtb-modred-inp.sh` just does the input with modred part
