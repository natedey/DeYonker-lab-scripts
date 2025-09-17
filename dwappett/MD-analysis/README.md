##MD simulation PDB extraction and analysis

these scripts set up for processing Atsu's CM long MD simulation (runs 08-25).
everything was done with slurm array jobs because processing 360000 frames takes a lot of time.

processing scripts:
- extract[_N].in is cpptraj input file. the double autoimage/align commands are necessary to get the whole protein centered in the unit cell so stuff doesn't end up in weird places in the pdb!!! this is set up to include the 600 closest waters to any of the chorismate ligands so roughly 200 in each active site. this could probably be reduced more but I wanted to be safe.


frame pdbs prep done by by job_process2:
- extract pdbs with cpptraj for each run (each run had an identical extract_N.in file just reading in that one run)
- separate each run into multiple dirs (labeled a-t, each containing only 1000 pdbs) for faster processing with rename.py
- submits second slurm job (job_addchain) in each dir to run add_chain.py on those 1000 pdbs

batch_rin script run on each dir by job_batchrin. did probe and arpeggio for each active site

probe-violins.py creates violin plots of contact counts for each FG in each of the three active sites to show spread
