#!/bin/bash

OUTPUT_DIR=reports/
FILENAME_PREFIX=""
FILENAME_SUFFIX=`date +%Y%m%d-%H%M%S`_
TYPE_OPER=false
TYPE_MGMT=false
TYPE_SELECTED=false
MIN_WARN=2
MIN_CRIT=20
MIN_FATAL=120


usage() { printf "Usage: $0\n\t -i <Input> <<Input log file to generate the report with>>\n\t [-d <Output directory>]\n\t [-p <Filename preffix>] <<You may specify a preffix for the generated file/s>>\n\t [-o] <<Operating report>>\n\t [-m] <<Management report>>\n\t [-w <minutes>] <<Minimum minutes to be considered a warning>>\n\t [-c <minutes>] <<Minimum minutes to be considered critical>>\n\t [-f <minutes>] <<Minimum minutes to be considered fatal>>\n" 1>&2; exit 1; }

while getopts ":d:p:o:m:w:c:f:i:" o; do
		case "${o}" in
				d)
					OUTPUT_DIR=${OPTARG};
					;;
				p)
					FILENAME_PREFIX=${OPTARG}
					;;
				o)
					TYPE_OPER=true
					TYPE_SELECTED=true
					;;
				m)
					TYPE_MGMT=true
					TYPE_SELECTED=true
					;;
				w)
					MIN_WARN=${OPTARG}
					;;
				c)
					MIN_CRIT=${OPTARG}
					;;
				f)
					MIN_FATAL=${OPTARG}
					;;
				i)
					INPUT_FILE=${OPTARG}
					;;
				*)
					usage
					;;
		esac
done
shift $((OPTIND-1))

# Input file parameter is mandatory
if [[ -z $INPUT_FILE ]]; then echo "No input log file specified."; usage; fi

# Default report type is Operating
if ! $TYPE_SELECTED; then TYPE_OPER=true; fi


#Begin
let FECHA=0
let FECHAANT="20141019 00:00:00"
while read line; do
#TODO: Hacer!
  FECHA=${line:0:17} 
  echo $FECHA
  echo $(( ($(date -ud "$FECHA" +%s) - $(date -ud "$FECHAANT" +%s) ) /60))
done < $INPUT_FILE
