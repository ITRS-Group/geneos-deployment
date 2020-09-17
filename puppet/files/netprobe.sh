#!/bin/bash
#
#set -x
#
#####################################################################
#
#       Program Name    :       netprobe.sh
#       Function        :       Execute ITRS Netprobe
#       Author          :       Richard Gould
#       Creation        :       23/08/2012
#       History :
#
#       23/08/2012      0.00 -> 1.00    RG      Creation
#	23/08/2012	1.00 -> 3.00	JH	new config file format
#
#####################################################################
#       Start of Local Tokens
#####################################################################

Program=${0##*/}
ProgramPath=${0%/*}
Firstchar=$(echo $ProgramPath | cut -c1)
if [ ! "$Firstchar" = "/" ]
then
        if [ "$Firstchar" = "." ]
        then
                ProgramPath=$(echo $ProgramPath | cut -c3-)
        fi
        ProgramPath=${PWD}/${ProgramPath}
fi
Version=3
Revision=00
Process="${Program} v${Version}.${Revision}"
Config=netprobe.cfg

#####################################################################
#       Start of Functions
#####################################################################

# -----------------------------------------------------------------------
# Function fn_Usage: Print usage details
# -----------------------------------------------------------------------

fn_Usage()
{
	echo
	echo "	Usage: ${Program} <netprobe name> <function>"
	echo "	Where <netprobe name> may be the netprobe name, \'all\' or the index number of the netprobe in the ${Config} file"
	echo "	Where <function> may be, start, stop, restart, list, command, status, usage"
	echo
	echo "	start           -       starts the netprobe or netprobes"
	echo "	stop            -       stops the netprobe or netprobes"
	echo "	restart         -       restarts the netprobe or netprobes"
	echo "	list            -       list the parameters of the netprobe or netprobes"
	echo "	command         -       displays the command line for starting the netprobe"
	echo "	status          -       displays the process stack for the netprobe"
	echo "	delete          -       remove the netprobe environment"
	echo "	usage|-h|-help  -       outputs this usage message"
	echo
}

# -----------------------------------------------------------------------
# Function fn_Message: Print message. Exit if message code = 1
# -----------------------------------------------------------------------

fn_Message()
{
        Now=$(date +"%Y-%m-%d %H.%M.%S")
        case $1 in
                1)      echo -e ${Now} : ${Process} : Error : $2
                        exit $1
			;;
                2)      echo -e ${Now} : ${Process} : Warn : $2
			;;
                3)      echo -e ${Now} : ${Process} : Info : $2
			;;
                *)      ;;
        esac
}

# -------------------------------------------------------------------------------------------------------------------------
# Function fn_Start: Start the netprobe in either foreground or backgroud depending on the NetMode setting for the netprobe
# -------------------------------------------------------------------------------------------------------------------------

fn_Start()
{
# ---
# Run Create XML Script for self announcing netprobe at Newedge
# ---

/opt/svc.itrs/np/netprobe/admin_scripts/create_xml_file.sh

# ---
# Create the command string
# ---
	Command="${NetRoot[${Index}]}/${NetBase[${Index}]}/${NetExec[${Index}]} ${NetName[${Index}]} ${NetPort[${Index}]}"
        Command="${Command} -port ${NetPort[${Index}]}"
        Command="${Command} ${NetOpts[${Index}]}"

	export LOG_FILENAME="${NetLogD[${Index}]}/${NetLogF[${Index}]}"

# ---
# if function is 'command' print the command else start
# ---
	if [ "${Function}" = "command" ]
	then
		NP_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${NetLibs[${Index}]}
		echo
		echo "COMMAND for ${NetName[${Index}]}: ${Command}"
		echo
		echo "LD_LIBRARY_PATH for ${NetName[${Index}]}: ${NP_LD_LIBRARY_PATH}"
		echo
	else
# ---
# Check netprobe environment has been created
# ---
		if [ ! -d  ${NetLogD[${Index}]} ]
		then
			fn_Message 3 "No netprobe log directory for ${NetName[${Index}]}. Creating netprobe environment... "
			fn_CreateDirs
		fi
	
		if [ ! -d  ${NetRoot[${Index}]}/${NetBase[${Index}]} ]
		then
			fn_Message 1 "No netprobe base for ${NetBase[${Index}]}. Please create link for this to the relevant binary package"
		fi

		case "${NetMode[${Index}]}" in
			BG)     LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${NetLibs[${Index}]}
				export LD_LIBRARY_PATH
# ---
# Check if netprobe is already running
# ---
			 	#started=$(pgrep -d " " -f "${NetExec[${Index}]} ${NetName[${Index}]} ${NetPort[${Index}]}")
			 	started=$(ps -ef | grep -v grep | grep -i "${NetExec[${Index}]} ${NetName[${Index}]} ${NetPort[${Index}]}" | wc -l)
				if [ "${started}" -eq 1 ]
				then
					fn_Message 1 "Netprobe ${NetName[${Index}]} ${NetPort[${Index}]} already running"	
				fi
# ---
# Start netprobe in background
# ---
				fn_Message 3 "Starting Netprobe ${NetName[${Index}]} ${NetPort[${Index}]}"
				nohup ${Command} > ${NetLogD[${Index}]}/netprobe.txt 2>&1 &
				sleep 5
				process=$(pgrep -d " " -f "${NetExec[${Index}]} ${NetName[${Index}]} ${NetPort[${Index}]}")
				if [ "${process}" -ne 0 ]
				then
					fn_Message 3 "Netprobe ${NetName[${Index}]} has started with PID : ${process}"
					fn_Message 3 "Netprobe ${NetName[${Index}]} logging to ${NetLogD[${Index}]}/${NetLogF[${Index}]}"
				else
					if [  ! -e ${NetLogD[${Index}]}/${NetLogF[${Index}]} ]
					then
						fn_Message 1 "Netprobe ${NetName[${Index}]} failed to start. ${NetLogD[${Index}]}/${NetLogF[${Index}]} for netprobe could not be created."
					fi
					fn_Message 3 "Netprobe ${NetName[${Index}]} has not started"
					fn_Message 3 "see - ${NetLogD[${Index}]}/${NetLogF[${Index}]}"
					fn_Message 3 "see - ${NetLogD[${Index}]}/netprobe.txt"
					fn_Message 3 "Last 20 lines of netprobe log file: "
					echo;tail -20 "${NetLogD[${Index}]}/${NetLogF[${Index}]}";echo
				fi
				;;
			FG)     LD_LIBRARY_PATH=${NetLibs[${Index}]}:${LD_LIBRARY_PATH}
				export LD_LIBRARY_PATH
				fn_Message 3 "Starting Netprobe ${NetName[${Index}]} ${NetPort[${Index}]}"
				${Command}
				;;
			*)	fn_Message 1 "No operating mode set. Should be BG for backgroud or FG or foreground"
				;;
		esac
	fi
}

# -----------------------------------------------------------------------
# Function fn_Stop: Stop the selected Netprobe
# -----------------------------------------------------------------------

fn_Stop()
{
        process=$(pgrep -d " " -f "${NetExec[${Index}]} ${NetName[${Index}]} ${NetPort[${Index}]}")
        if [ $? -eq 0 ]
	then
		fn_Message 3 "Stopping Netprobe - ${process}"
		kill ${process}
	fi
	sleep 3
        process=$(pgrep -d " " -f "${NetExec[${Index}]} ${NetName[${Index}]} ${NetPort[${Index}]}")
        if [ $? -eq 0 ]
	then
		fn_Message 2 "Netprobe ${NetName[${Index}]}, process ${process} failed to be stopped"
	else
		fn_Message 3 "Netprobe ${NetName[${Index}]} stopped"
	fi
}

# -----------------------------------------------------------------------
# Function fn_Status: Show the ps details for the select Netprobe
# -----------------------------------------------------------------------

fn_Status()
{
        process=$(pgrep -d " " -f "${NetExec[${Index}]} ${NetName[${Index}]} ${NetPort[${Index}]}")
        if [ $? -eq 0 ]
	then
		ps -lfp ${process}
	else
		fn_Message 3 "Netprobe ${NetName[${Index}]} is not running"
	fi
}

# ---------------------------------------------------------------------------
# Function fn_List: List all of the current settings for the selected Netprobe
# ---------------------------------------------------------------------------

fn_List()
{
        fn_Message 3 "Netprobe details for Instance ${Index} - ${NetName[${Index}]}"
        echo ""
        echo "    Netprobe Host     = ${NetHost[${Index}]}"
        echo "    Netprobe Root     = ${NetRoot[${Index}]}"
        echo "    Netprobe Name     = ${NetName[${Index}]}"
        echo "    Netprobe Base     = ${NetBase[${Index}]}"
        echo "    Netprobe Binary   = ${NetExec[${Index}]}"
        echo "    Netprobe Port     = ${NetPort[${Index}]}"
        echo "    Netprobe Resource = ${NetReso[${Index}]}"
        echo "    Netprobe Log File = ${NetLogD[${Index}]}/${NetLogF[${Index}]}"
        echo "    Extra Options     = ${NetOpts[${Index}]}"
        echo "    Fore/Back ground  = ${NetMode[${Index}]}"
        echo "    Libraries         = ${NetLibs[${Index}]}"
        echo ""
}

# -----------------------------------------------------------------------
# Function fn_NetList: Display the list of netprobe in the config file
# -----------------------------------------------------------------------

fn_NetList()
{
        for x in $(grep "I=" ${ProgramPath}/${Config} | tr -d " " | grep -v "^#" | cut -d"=" -f2)
        do
                echo "Netprobe ${x}: ${NetName[${x}]}"
        done
}

# -----------------------------------------------------------------------
# Function fn_SetParams: Set the parameters for the netprobe
# -----------------------------------------------------------------------

fn_SetParams()
{

# ---
# first check that values exist in the config file for the netprobe name and port
# ---

	if [ -z "${NetName[${Index}]}" ]; then fn_Message 1 "No netprobe name set for instance ${Index}" ; fi
	if [ -z "${NetPort[${Index}]}" ]; then fn_Message 1 "No port number set for instance ${Index}" ; fi

	if [ -z "${NetRoot[${Index}]}" ]; then NetRoot[${Index}]=${defNetRoot} ; fi
	if [ -z "${NetBase[${Index}]}" ]; then NetBase[${Index}]=${defNetBase} ; fi
	if [ -z "${NetExec[${Index}]}" ]; then NetExec[${Index}]=${defNetExec} ; fi
	if [ -z "${NetHost[${Index}]}" ]; then NetHost[${Index}]=${defNetHost} ; fi
	if [ -z "${NetMode[${Index}]}" ]; then NetMode[${Index}]=${defNetMode} ; fi
	if [ -z "${NetOpts[${Index}]}" ]; then NetOpts[${Index}]=${defNetOpts} ; fi
	if [ -z "${NetLogF[${Index}]}" ]; then NetLogF[${Index}]=${defNetLogF} ; fi
	if [ -z "${NetLogD[${Index}]}" ]; then NetLogD[${Index}]=${defNetLogD} ; fi
	NetLogD[${Index}]=${NetRoot[${Index}]}/${NetLogD[${Index}]}/${NetName[${Index}]}
	if [ -z "${NetReso[${Index}]}" ]; then NetReso[${Index}]=${NetRoot[${Index}]}/${NetBase[${Index}]}/resources ; fi
	if [ -z "${NetLibs[${Index}]}" ]; then NetLibs[${Index}]=${NetRoot[${Index}]}/${NetBase[${Index}]}/lib:. ;  fi
}

# --------------------------------------------------------------------------------------------------------------
# Function fn_CreateDirs: Create the relevant directories for the netprobe and copy over the default setup files
# --------------------------------------------------------------------------------------------------------------

fn_CreateDirs()
{
	fn_Message 3 "Creating directories for ${NetName[${Index}]}"
	mkdir ${NetLogD[${Index}]}
	fn_Message 3 "Environment created for ${NetName[${Index}]}"
}

# -----------------------------------------------------------------------
# Function fn_RemoveDirs: Remove the relevant directories for the netprobe
# -----------------------------------------------------------------------

fn_RemoveDirs()
{
	echo; fn_Message 3 "Are you sure you want to remove all directories and contents for ${NetName[${Index}]}? [Y/N] \\c"
	read input
	if [ "${input}" = "y" -o "${input}" = "Y" ]
	then
		started=$(pgrep -d " " -f "${NetExec[${Index}]} ${NetName[${Index}]} ${NetPort[${Index}]}")
		if [ "${started}" -gt 1 ]
		then
			fn_Message 3 "Netprobe ${NetName[${Index}]} is currently running. Shutting down..."
			fn_Stop
		fi
		fn_Message 3 "Deleting directories for ${NetName[${Index}]}"
		rm -r ${NetLogD[${Index}]}
		fn_Message 3 "Netprobe ${NetName[${Index}]} removed"
	else
		fn_Message 3 "Operation cancelled"
	fi
}

# ----------------------------------------------------------------------
# function fn_CheckValidity: Check validity of netprobe instance supplied
#                            and set the Index value
# ----------------------------------------------------------------------

fn_CheckValidity()
{
case ${Instance} in
	[1-9]|[0-9][0-9])	if [ $(grep -c I=${Instance} ${ProgramPath}/${Config}) -lt 1 ]
				then 
					fn_NetList 
					fn_Message 1 "Cannot find Instance Number ${Instance}"
				elif [ $(grep -c "I=${Instance}$" ${ProgramPath}/${Config}) -gt 1 ]
				then
					fn_NetList
					fn_Message 1 "Multiple instances of Instance Number ${Instance} found"
				else
					Index=${Instance}
				fi
				;;
	[a-z]*|[A-Z]*)		if [ $(grep -c "NetName.*${Instance}" ${ProgramPath}/${Config}) -lt 1 ]
				then
					fn_NetList
					fn_Message 1 "Error : Netprobe ${Instance} not found" 
				elif [ $(grep -c "NetName.*${Instance}" ${ProgramPath}/${Config}) -gt 1 ]
				then
					fn_NetList
					fn_Message 1 "Multiple instances of Netprobe ${Instance} found" 
				else
					Index=$(grep -B3 ${Instance} ${ProgramPath}/${Config} | grep "I=" | tr -d " " | grep -v "^#" | cut -d"=" -f2)
				fi
				;;
	*)			fn_Usage
				exit 0
				;;
esac
}

# -----------------------------------------------------------------------
# Function fn_PerformFunction: run the relevant function (arg 2)
# -----------------------------------------------------------------------

fn_PerformFunction()
{
	if [ "${Function}" = "" ]
	then
		fn_Usage
		fn_Message 1 "Please include a relevant function"
	fi

        case ${Function} in
                start)          fn_Start	    	                  ;;
                stop)           fn_Stop                		          ;;
                restart)        fn_Stop ; sleep 20 ; fn_Start             ;;
                status)         fn_Status                                 ;;
                list)           fn_List                                   ;;
		delete)		fn_RemoveDirs				  ;;
		command)	fn_Start "command"                        ;;
                usage|-h|-help) fn_Usage ; exit 0			  ;;
                *)              fn_Usage ; exit 0                         ;;
        esac
}

# -----------------------------------------------------------------------
# Function fn_CheckConfig: check for existence of config file and run it
#                          to set the variables
# -----------------------------------------------------------------------

fn_CheckConfig()
{
	if [ -f ${ProgramPath}/${Config} ]
	then
		. ${ProgramPath}/${Config}
	else
		fn_Message 1 "Netprobe configuration file (${Config}) not found"
	fi
}

#######################################################################################
#       End of Functions
#######################################################################################
#
#       Start of Main Script
#
#######################################################################################

# ----------
# Set local variables
# ----------

HostName=$(hostname)
UserName=${LOGNAME}
OS=$(uname -s)
Instance=$1
Function=$2

# ---------
# Check the config file
# ---------

fn_CheckConfig

# --------
# run against all instances, or check the validity of the single instance entered
# for each instance; set the default parameters and run the required function
# --------

case ${Instance} in
        all)	for x in $(grep "I=" ${ProgramPath}/${Config} | tr -d " " | grep -v "^#" | cut -d"=" -f2)
		do
			Index=$x
			fn_SetParams
			fn_PerformFunction
		done
		;;
        usage|-h|-help) fn_Usage
			exit 0
			;;
        *)	fn_CheckValidity
		fn_SetParams
		fn_PerformFunction
		;;
esac

###########################################################
#
#       EOS End of Script
#
###########################################################

