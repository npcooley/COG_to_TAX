#! /bin/bash

# because we're grabbing 'static' files from the FTP site, and we're not
# asking any questions of the data till later, the only thing we do up front is
# create the first log files directory

# create the log files directory if it doesn't exist already
if [[ ! -d "LogFilesA" ]]; then
  mkdir LogFilesA
fi

if [[ ! -f "shorthandlogs.txt" ]]; then
  # if the log files doesn't exist, create it and give the start date
  echo "DAG Start:" > shorthandlogs.txt
  date >> shorthandlogs.txt
else
  # else append the restart date
  echo "DAG Restart:" >> shorthandlogs.txt
  date >> shorthandlogs.txt
fi

