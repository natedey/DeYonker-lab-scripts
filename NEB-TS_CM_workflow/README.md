# stuff for NEB-TS-based workflow

Preliminary setup/checking scripts prepared by DAW July 2026 based on NJD's first test.
Tested in /project/dwappett/chorismate_mutase/QM-A/test-NEB-f00001-f00010
(note that those have a slightly different folder structure because I didn't initially have the freq keyword 
in the NEB-TS input, it was done as a subsequent job, but that's fixed now)

Existing workflow does initialopt -> tsconstrained -> tsopt -> ircs. 
This workflow does reactant -> product -> neb-ts.

Steps:
1. reactant: basically same as initialopt. set up with standard md qm setup script
2. product: guess prepared by fitting old product ligand geom into reactant/initialopt struc 
   (just like how tsguess prepared normally). set up with cmsetup-productguess.sh
3. neb-ts: find ts from reactant and product structures. set up with cmsetup-neb-ts.sh

Notes:
-  check_cm_jobs_neb_workflow.sh is modified to work with this workflow but ts checking very rudimentary,
   have not done any of the thinking/decision-making about when/how to restart neb-ts jobs automatically.
   only labels neb-ts jobs as done/running/freqcrash/check_manually
   (haven't tested if redo-freq will even work to restart freqcrash but unlikely to occur when running in /tmp/).
   initialopt/reactant and product have same statuses as ircs in normal workflow, redo-opt should work fine

-  also haven't made a matching version of cm-md-status.py to tabulate statuses, you have to look at raw lists

-  product guess created from product of second largest probe model (res_12) from Atsu's study. 
   this is NOT the same model as used for ts guesses (those use max model, res_13) because the max model product
   was a bit more "open" which might cause issues with fitting. res_12 prod more compact/less likely to clash

-  didn't change the align_TSA_and_replace.py script to generalise language, setup script just renames outputs.
   stuff printed to the terminal there will still mention tsguess.pdb/tsguess_close_atoms.txt,
   but the outputs will be renamed as productguess.pdb/productguess_close_atoms.txt in the directories

-  if/when you start using this workflow properly and someone improves these scripts, it might be clearer 
   to change "initialopt" to "reactant" but I didn't bother for now

-  NEB-TS can be given a tsguess as well - if first attempt with reactant and product doesn't work,
   next attempt could be to do a tsconstrained as well and then use that in the neb-ts? 
