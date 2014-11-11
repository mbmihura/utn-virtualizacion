#!/bin/bash

OUTPUT_DIR=reports/
FILENAME_PREFIX="Reporte_"
FILENAME_SUFFIX=`date +%Y%m%d-%H%M%S`_
TYPE_OPER=false
TYPE_MGMT=false
TYPE_SELECTED=false
MIN_WARN=2
MIN_CRIT=20
MIN_FATAL=60


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
let LINE_NUMBER=0
let DOWN=false
let LAST_DATE=0
let TIME_DOWN=0
let INTERVAL=0
let TIME_DOWN_MIN=0
SERV=${INPUT_FILE%.*}
SERV=${SERV#*\/}
while read line; do
#TODO: Hacer!
  let LINE_NUMBER=$(($LINE_NUMBER + 1))
  DATE=${line:0:17}
  if [[ $LINE_NUMBER == 1 ]]; then
      LAST_DATE=$DATE
  fi
  if [[ $line == *LOG\ SESSION\ START\ AT* ]]; then
    let LINE_NUMBER=0
    let TIME_DOWN=0
  fi

  if date -d "$DATE" >/dev/null 2>&1;then
    if [[ $line == *NORESPONSE* ]]; then
      if [[ $DOWN ]]; then
        INTERVAL=$(($(date -ud "$DATE" +%s) - $(date -ud "$LAST_DATE" +%s)))
        TIME_DOWN=$(($TIME_DOWN + $INTERVAL))
        TIME_DOWN_MIN=$(($TIME_DOWN / 60))
        if (( "$TIME_DOWN_MIN" > "$MIN_WARN" )); then
            if (( "$TIME_DOWN_MIN" < "$MIN_CRIT" )); then
                echo "${DATE} WARNING: ${SERV} ${TIME_DOWN_MIN} minutos sin servicio" >> "${OUTPUT_DIR}${FILENAME_PREFIX}${FILENAME_SUFFIX}${SERV}.txt"
            else
                if (( "$TIME_DOWN_MIN" < "$MIN_FATAL" )); then
                    echo "${DATE} CRITICAL: ${SERV} ${TIME_DOWN_MIN} minutos sin servicio" >> ./reporte.txt
                else
                    echo  "${DATE} FATAL: ${SERV} ${TIME_DOWN_MIN} minutos sin servicio" >> ./reporte.txt
                fi
            fi
        fi
      else
        DOWN=true
      fi
    fi
    if [[ $line == *OK* ]]; then
        DOWN=false
        TIME_DOWN=0
    fi
    LAST_DATE=$DATE
  fi
done < $INPUT_FILE
