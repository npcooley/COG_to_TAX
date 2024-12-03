#! /bin/bash

# # collect current completed jobs
shopt -s nullglob
for file in Result*.RData; do
  [[ -f $file && -s $file ]] && printf '%s\n' "$file"
done > CompletedResults.txt

# nuke the Run.dag associated files
rm Collection/Run.dag.*

VAR1=$(<CompletedResults.txt wc -l)
VAR2=$(<ExpectedResults.txt wc -l)
# collection tracker starts at 0 
ITERATION=$(tail -n 1 Tracker_B.txt)
LIMIT=3

if [[ "$VAR1" -eq "$VAR2" ]]; then
  echo 'All results completed!' >> shorthandlogs.txt
  date >> shorthandlogs.txt
  exit 0
else
  if [[ "$ITERATION" -ge "$LIMIT" ]]; then
    echo 'Iteration limit reached!' >> shorthandlogs.txt
    date >> shorthandlogs.txt
    exit 0
  fi
  # iteration bump happens in the pre-collection, this is not necessary
  # ((ITERATION++))
  # echo "$ITERATION" >> Tracker_B.txt
  echo 'Iteration completed with missing results, restarting!' >> shorthandlogs.txt
  date >> shorthandlogs
  exit 1
fi

