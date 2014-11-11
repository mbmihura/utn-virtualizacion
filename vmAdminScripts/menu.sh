#!/bin/bash

trap '' 2  # ignore control + c

while true
do
	clear # clear screen for each loop of menu

	echo "===================================================================="
	echo "                 Infraestructura y Virtualizacion                   "
	echo "                     Automatizador de Tareas                        "
	echo "===================================================================="
	echo "1.- Start Virtual Machines     "
	echo "2.- Fail-over                  "
	echo "3.- Fail-back                  "
	echo "4.- Disaster Recovery          "
	echo "5.- Start Monitoring           "
	echo "6 - Generate Report            "
	echo "q.- Exit                       "
	echo -e "Enter your selection here and hit <return> \c"

	read answer  # create variable to retains the answer

	case "$answer" in
		1) clear # clear screen for each loop of menu
		   echo "===================================================================="
		   echo "                 Infraestructura y Virtualizacion                   "
		   echo "                     Automatizador de Tareas                        "
		   echo "                                                                    "
		   echo "                     Start Virtual Machines                         "
		   echo "===================================================================="
		   echo "Enter 1 to start VM 1:"
		   echo "Enter 2 to start VM 2:"
		   echo "Enter 3 to go back:"
		   echo -e "Enter your selection here and hit <return> \c"

		   read vm  # create variable to retains the answer
		   
		   case "$vm" in
				1) ./start-machine.sh 1 >/dev/null 2>&1 < /dev/null &;;
				2) ./start-machine.sh 2 >/dev/null 2>&1 < /dev/null &;;
				3) ;;
		   esac;;
		   
		2) clear # clear screen for each loop of menu
		   echo "===================================================================="
		   echo "                 Infraestructura y Virtualizacion                   "
		   echo "                     Automatizador de Tareas                        "
		   echo "                                                                    "
		   echo "                           Fail-over                                "
		   echo "===================================================================="
		   echo "Enter 1 to shutdown VM 1 - Automatic fail-over to VM 2:"
		   echo "Enter 2 to shutdown VM 2 - Automatic fail-over to VM 1:"
		   echo "Enter 3 to go back:"
		   echo -e "Enter your selection here and hit <return> \c"

		   read vm  # create variable to retains the answer
		   
		   case "$vm" in
				1) ./stop-machine.sh 1 >/dev/null 2>&1 < /dev/null &;;
				2) ./stop-machine.sh 2 >/dev/null 2>&1 < /dev/null &;;
				3) ;;
		   esac;;
		   
		3) clear # clear screen for each loop of menu
		   echo "===================================================================="
		   echo "                 Infraestructura y Virtualizacion                   "
		   echo "                     Automatizador de Tareas                        "
		   echo "                                                                    "
		   echo "                           Fail-back                                "
		   echo "===================================================================="
		   echo "Enter 1 to start VM 1 - Automatic fail-back:"
		   echo "Enter 2 to start VM 2 - Automatic fail-back:"
		   echo "Enter 3 to start VM 1 and VM2 - Automatic fail-back from DR:"
		   echo "Enter 3 to go back:"
		   echo -e "Enter your selection here and hit <return> \c"

		   read vm  # create variable to retains the answer
		   
		   case "$vm" in
				1) ./vmAdminScripts/start-machine.sh 1 >/dev/null 2>&1 < /dev/null & ;;
				2) ./vmAdminScripts/start-machine.sh 2 >/dev/null 2>&1 < /dev/null &;;
				3) ./vmAdminScripts/start-machine.sh 1 >/dev/null 2>&1 < /dev/null &
                    sleep 2
				   ./vmAdminScripts/start-machine.sh 2 >/dev/null 2>&1 < /dev/null &;;				
				4) ;;
		   esac;;
		   
		4) clear # clear screen for each loop of menu
		   echo "===================================================================="
		   echo "                 Infraestructura y Virtualizacion                   "
		   echo "                     Automatizador de Tareas                        "
		   echo "                                                                    "
		   echo "                       Disaster-Recovery                            "
		   echo "===================================================================="
		   echo "Enter 1 to shutdown VM 1 and VM 2 - Automatic disaster-recovery:"
		   echo "Enter 3 to go back:"
		   echo -e "Enter your selection here and hit <return> \c"

		   read vm  # create variable to retains the answer
		   
		   case "$vm" in
				1) ./stop-machine.sh 1 >/dev/null 2>&1 < /dev/null &
                    sleep 10
				   ./stop-machine.sh 2 >/dev/null 2>&1 < /dev/null & ;;
				3) ;;
		   esac;;		   
		 
		5) ./start-all-watchdogs.sh >/dev/null 2>&1 < /dev/null & ;;
		
		6) ./launch-all-reports.sh >/dev/null 2>&1 < /dev/null &;;
		 
		q) exit;;
	esac
	read input ##This cause a pause so we can read the output
done
