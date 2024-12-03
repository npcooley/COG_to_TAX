#! /bin/bash

WatcherCount=14400
COGs=($(awk '{print $2}' COG_table.txt))

# collect current completed jobs
shopt -s nullglob
for file in Result*.RData; do
  [[ -f $file && -s $file ]] && printf '%s\n' "$file"
done > CompletedResults.txt

CompletedCOGS=$(<CompletedResults.txt wc -l)
ExpectedCOGS=$(<ExpectedResults.txt wc -l)
echo "There are ${ExpectedCOGS} results expected and ${CompletedCOGS} results already present, building DAG for remaining." >> shorthandlogs.txt
date >> shorthandlogs.txt

# if the DAG exists and has been run before, rewrite it and nuke the associated files
DAG="Run.dag"
if [[ -f ${DAG} ]]; then
  rm "${DAG}"
  # Run.dag's associated files shouldn't ever appear in this directory
  # rm "${DAG}.*"
  # start the dag with the watcher
  cp Chronos.txt "${DAG}"
  printf "\n" >> "${DAG}"
  # echo "a"
  # cat ${DAG}
  sed -i "s/PLACEHOLDER/${WatcherCount}/g" "${DAG}"
  # echo "${Chronos}" > "${DAG}"
else
  # start the dag with the watcher
  cp Chronos.txt "${DAG}"
  printf "\n" >> "${DAG}"
  # echo "b"
  # cat ${DAG}
  sed -i "s/PLACEHOLDER/$WatcherCount/g" "${DAG}"
  # echo "${Chronos}" > "${DAG}"
fi

# reset the iterator
CurrentIterator=1
# loop through the expected results
while IFS= read -r line; do
  # only write out lines that are needed
  if ! grep -Fxq "$line" CompletedResults.txt; then
    printf 'JOB B%d Collection/Run.sub\n' "${CurrentIterator}" >> "${DAG}"
    printf 'VARS B%d COG="%s" ID="%d"\n' ${CurrentIterator} ${COGs[((${CurrentIterator} - 1))]} ${CurrentIterator} >> "${DAG}"
  fi
  ((CurrentIterator++))
done < ExpectedResults.txt

printf "\nABORT-DAG-ON WATCHER 2 RETURN 1\n" >> "${DAG}"

mv "${DAG}" Collection/"${DAG}"

# check or create the tracker
if [[ -f "Tracker_B.txt" ]]; then
  ITERATION=$(tail -n 1 Tracker_B.txt)
  ((ITERATION++))
  echo "$ITERATION" >> Tracker_B.txt
else
  echo "1" > Tracker_B.txt
fi

# check or create the log files
if [[ ! -d "LogFilesBA" ]]; then
  mkdir LogFilesBA
else
  rm -f LogFilesBA/*
fi
