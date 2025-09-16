#!/bin/bash

# DAW 9/9/25
# script to do test-completion on recently finished jobs
# saves hidden date file in home dir so by default it can check everything since you last checked
# optional arguments for other time periods: h (hour), d (day), w (weekend = since friday 5pm), s (specify date/time)
# FOR ANYONE ELSE USING THIS: note that I have set my preferred date/time format (DD Mon HH:MM) for slurm commands in my bashrc as:
#  > export SLURM_TIME_FORMAT="%d %b %H:%M"
# the finished time column output by this might look weird with whatever the default is!

# if no argument specified, checks since last checked
if [ -z $1 ]; then
  lc="$HOME/.lastqftest.txt"
  if [ -f $lc ]; then
    echo "--SINCE LAST CHECKED AT $(cat $lc | sed "s/T/ /")--"
    sacct -u "$USER" -X -S "$(cat $lc)" -E now -s CA,CD,DL,OOM,F,TO -o end%-14,jobid%-8,state%-20,elapsed%12,workdir%-120 | (sed -u 2q; sort -k1,3) | awk 'NR>2' > .qftmp.txt
    date +%Y-%m-%dT%H:%M > $HOME/.lastqftest.txt
  else
    echo "Can't determine when last check was. Run with a specific time argument (h/d/w/s)"
    exit
  fi

# argument h checks last hour
elif [[ "$1" == "h" ]]; then
  echo "--LAST HOUR--"
  sacct -u "$USER" -X -S now-1hour -E now -s CA,CD,DL,OOM,F,TO -o end%-14,jobid%-8,state%-20,elapsed%12,workdir%-120 | (sed -u 2q; sort -k1,3) | awk 'NR>2' > .qftmp.txt
  date +%Y-%m-%dT%H:%M > $HOME/.lastqftest.txt

# argument d checks last day
elif [[ "$1" == "d" ]]; then
  echo "--LAST 24 HOURS--"
  sacct -u "$USER" -X -S now-1day -E now -s CA,CD,DL,OOM,F,TO -o end%-14,jobid%-8,state%-20,elapsed%12,workdir%-120 | (sed -u 2q; sort -k1,3) | awk 'NR>2' > .qftmp.txt
  date +%Y-%m-%dT%H:%M > $HOME/.lastqftest.txt

# argument w checks since 5pm last friday (for the weekend)
elif [[ "$1" == "w" ]]; then
  echo "--SINCE FRIDAY 5PM--"
  fd=$(date --date='17:00 last Fri' +%m%d-%H:%M)
  sacct -u "$USER" -X -S $fd -E now -s CA,CD,DL,OOM,F,TO -o end%-14,jobid%-8,state%-20,elapsed%12,workdir%-120 | (sed -u 2q; sort -k1,3) | awk 'NR>2' > .qftmp.txt
  date +%Y-%m-%dT%H:%M > $HOME/.lastqftest.txt

# argument s followed by date/time gives specific start time for period to check
elif [[ "$1" == "s" ]]; then
  if [ -z $2 ]; then
   echo "argument \"s\" needs to be followed by start time (MMDD, HH:MM, MMDD-HH:MM etc)"
   exit
  else
   echo "--SINCE $2--"
   sacct -u "$USER" -X -S $2 -E now -s CA,CD,DL,OOM,F,TO -o end%-14,jobid%-8,state%-20,elapsed%12,workdir%-120 | (sed -u 2q; sort -k1,3) | awk 'NR>2' > .qftmp.txt
   date +%Y-%m-%dT%H:%M > $HOME/.lastqftest.txt
  fi

# warn and quit if unrecognised argument given
else 
  echo "Recognised arguments are h/d/w/s"
  exit
fi


njob=$(cat .qftmp.txt | wc -l)
printf "Finished         Run Time Completion Path\n------------ ------------ ---------- ----\n"
for ((i=1;i<=$njob;i++)); do
  t=$(awk 'NR=='$i' {print $1, $2, $3}' .qftmp.txt)
  d=$(awk 'NR=='$i' {print $(NF-1)}' .qftmp.txt)
  p=$(awk 'NR=='$i' {print $NF}' .qftmp.txt)
  if [ -f "${p}/1.out" ]; then 
    comp=$(test-completion-daw.sh $p | grep "${p}/1.out" | awk '{print $1}' | sed "s/://")
  else
    comp="none"
  fi
  #printf "%-12s %-12s %-10s %s\n" $t $d $comp $p
  printf "%-2s %-3s %-5s %12s %-10s %s\n" $t $d $comp $p
done

rm .qftmp.txt

