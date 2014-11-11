#!/bin/bash
setsid ./generate-report.sh -i logs/iyv01.log >/dev/null 2>&1 < /dev/null &
setsid ./generate-report.sh -i logs/iyv02.log >/dev/null 2>&1 < /dev/null &
setsid ./generate-report.sh -i logs/iyvdr.log >/dev/null 2>&1 < /dev/null &
setsid ./generate-report.sh -i logs/db-iyv.log >/dev/null 2>&1 < /dev/null &
setsid ./generate-report.sh -i logs/app-iyv.log >/dev/null 2>&1 < /dev/null &
setsid ./generate-report.sh -i logs/app-iyv.log >/dev/null 2>&1 < /dev/null &
DIR=$@   
cd reports
dir=$(dir -1)
for file in $dir;
do
  if [ -n $file ]; then
    path_and_name=${file%.*}
    exec enscript -p "${path_and_name}".ps  "${path_and_name}".txt >/dev/null 2>&1 < /dev/null &
 
  fi;
done;
sleep 5
for file in $dir;
do
  if [ -n $file ]; then
    path_and_name=${file%.*}
    exec ps2pdf "${path_and_name}".ps  "${path_and_name}".pdf >/dev/null 2>&1 < /dev/null &
  fi;
done;
rm -R *.ps
