#! /bin/bash

# create an array out of the collected COGs
# we need to replace the PLACEHOLDER in Chronos, this is our variable for that
# it is in seconds


if [[ -f "COG_table.txt" ]]; then
  COGs=($(awk '{print $2}' COG_table.txt))
  Cog_Total=${#COGs[@]}
  echo "$Cog_Total COGs identified from the NCBI." >> shorthandlogs.txt
  date >> shorthandlogs.txt
else
  echo "COG_table is missing, check Node A's error and output files." >> shorthandlogs.txt
  date >> shorthandlogs.txt
  exit 1
fi

# write out a job map if one doesn't already exist, this can be used to build a DAG

if [[ ! -f "JobMapB.txt" ]]; then
  CurrentIterator=1
  for ((m1=0; m1<${#COGs[@]}; m1++)); do
    # does this need a note?
    printf "${CurrentIterator} ${COGs[m1]} Result%05d.RData\n" $CurrentIterator
    ((CurrentIterator++))
  done > JobMapB.txt
fi

# if a list of expected results does not exist, create it
if [[ ! -f "ExpectedResults.txt" ]]; then
  for PersistentID in $(cut -f1 -d " " JobMapB.txt); do
    printf 'Result%05d.RData\n' ${PersistentID}
  done > ExpectedResults.txt
fi

# this should end our post planning responsibilities
# when we trigger the collection subdag, its first step will need to be the creation
# of its run dag
# the run.sh, run.sub, and run.R files will be in place already and can be referenced accordingly

# # collect current completed jobs
# shopt -s nullglob
# for file in Result*.RData; do
#   [[ -f $file && -s $file ]] && printf '%s\n' "$file"
# done > CompletedResults.txt
# 
# CompletedCOGS=$(wc -l CompletedResults.txt)
# ExpectedCOGS=$(wc -l ExpectedResults.txt)
# echo "${ExpectedCOGS} results expected and ${CompletedCOGS} results already exist, building DAG for remaining.\n" >> shorthandlogs.txt
# 
# # if the DAG exists and has been run before, rewrite it and nuke the associated files
# DAG="Collection.dag"
# if [[ -f ${DAG} ]]; then
#   rm "${DAG}"
#   rm "${DAG}.*"
#   # start the dag with the watcher
#   cp Chronos.txt "${DAG}"
#   printf "\n" >> "${DAG}"
#   # echo "a"
#   # cat ${DAG}
#   sed -i "s/PLACEHOLDER/$WatcherCount/g" "${DAG}"
#   # echo "${Chronos}" > "${DAG}"
# else
#   # start the dag with the watcher
#   cp Chronos.txt "${DAG}"
#   printf "\n" >> "${DAG}"
#   echo "b"
#   # cat ${DAG}
#   sed -i "s/PLACEHOLDER/$WatcherCount/g" "${DAG}"
#   # echo "${Chronos}" > "${DAG}"
# fi
# 
# # reset the iterator
# CurrentIterator=1
# # loop through the expected results
# while IFS= read -r line; do
#   # only write out lines that are needed
#   if ! grep -Fxq "$line" CompletedResults.txt; then
#     printf 'JOB B%d Collection/Collection.sub\n' "${CurrentIterator}" >> "${DAG}"
#     printf 'VARS B%d COG="%s"\n' "${CurrentIterator}" ${COGs[((${CurrentIterator} - 1))]} >> "${DAG}"
#   fi
#   ((CurrentIterator++))
# done < ExpectedResults.txt
# 
# printf "\nABORT-DAG-ON WATCHER 2 RETURN 1\n" >> "${DAG}"
# 
# mv "${DAG}" Collection/"${DAG}"

# start and end conditions need to be managed within each subdag so 



