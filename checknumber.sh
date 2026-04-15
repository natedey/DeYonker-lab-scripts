# !/bin/bash
# HKS 04/15/2026
# this script loops over the directories listed in to-collect.txt (the one we made to run 1-collect),runs cm-md-status.py in each, extracts the last line, and collects the “done vs total” counts to give an overall count of jobs done. 
# You may need to run check_cm_jobs.sh in all directories to ensure the numbers are fully up to date



done_total=0
all_total=0

for d in $(cat to-collect.txt); do
    if [ ! -d "$d" ]; then
        continue
    fi

    line=$(cd "$d" &&  cm-md-status.py | tail -n 1)

    echo "number: $d --> $line"

    done_count=$(echo "$line" | grep -oE '[0-9]+' | sed -n '1p')
    total_count=$(echo "$line" | grep -oE '[0-9]+' | sed -n '2p')

    if [ -n "$done_count" ] && [ -n "$total_count" ]; then
        done_total=$((done_total + done_count))
        all_total=$((all_total + total_count))
        echo "$d : $done_count out of $total_count"
    else
        echo "$d : could not read status"
    fi
done

echo
echo "$done_total out of $all_total models fully done"
