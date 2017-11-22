#!/usr/bin/bash
function serverstatus {
	PORT=$1
	#STATE=$(java weblogic.Admin GETSTATE -url t3://$HOST:$PORT -username $WL_USER -password $WL_PASSWORD)
	#if [[ -n "$(echo $STATE | awk '/RUNNING/')" ]]
        STATE=$(netstat -anlpt|grep $PORT |wc -l)
	if [[ $STATE -ne 0 ]]
	then
		echo "RUNNING"
	else
		echo "NOT RUNNING"
	fi
}

function startserver {
	PORT=$1
	SERVER_TYPE=$2
	SBM_DOMAIN_DIR=$3
	START_SERVER_CMD=$4
	LOG_FILE=$5
	CACHE_DIR=$6

	cd $SBM_DOMAIN_DIR
	[[ $? -ne 0 ]] && { echo "Couldn't cd to $SBM_DOMAIN_DIR!"; exit 1; }

	[[ ! -x $START_SERVER_CMD ]] && { echo "Unable to execute $START_SERVER_CMD!"; exit 1; }

	STARTED_SERVER="N"
	COUNT=0
	while true
	do
		# Check if server is in RUNNING mode
		SERVER_STATE=$(serverstatus $PORT)
		if [[ $SERVER_STATE = "RUNNING" ]]
		then 
			if [[ $STARTED_SERVER = "Y" ]]
			then
				echo "[$SERVER_TYPE Server Started]"
			else
				echo "[$SERVER_TYPE Server already Running]"
			fi
			break
		elif [[ $STARTED_SERVER = "Y" ]]
		then
			((COUNT=COUNT+1))
			[[ $COUNT -gt 720 ]] && { echo "$SERVER_TYPE did not start in a reasonable amount of time!"; exit 1; }
			echo ".\c"
			sleep 5
		else
			echo "Starting $SERVER_TYPE Server"			
			nohup $START_SERVER_CMD 2>&1 &
			STARTED_SERVER="Y"
		fi
	done
}

function startAdminServer {
	startserver $ADMIN_PORT "Admin" $SBM_DOMAIN_DIR "./startAdminServer.sh" 
}

function usage {
	echo "USAGE: $(basename $0) start|stop|status|setup "
}

SBM_DOMAIN_DIR=/usr/weblogic1036/user_projects/domains/sbm76
SBM_BIN_DIR=/opt/SBM764/bin
ADMIN_PORT=14002
EJB_PORT=16003
PORTAL_PORT=18793
HOST=$(hostname)
WL_USER=system
WL_PASSWORD=wlsysadmin

case $1 in
start)
	# Start Admin server, wait for completion
	startAdminServer
	
	# Start EJB and Portal servers in parallel, wait for completion
	startserver $EJB_PORT "EJB" $SBM_DOMAIN_DIR "./startEjbServer.sh"  &
	EJB_PID=$!
	startserver $PORTAL_PORT "Portal" $SBM_DOMAIN_DIR "./startPortalServer.sh"  &
	PORTAL_PID=$!
	wait $EJB_PID $PORTAL_PID

	# Start event publisher
	echo "Starting Event Publisher Server"
	cd $SBM_BIN_DIR 
	./startEventPublisher.sh | grep -v 'Event Publisher Started'
	;;
stop)
	echo "Stopping portalServer..."
	kill -9 `netstat -nlp | grep -w  18793 | sed -r 's#.* (.*)/.*#\1#'`
	echo "Stopping ejbServer..."
	kill -9 `netstat -nlp | grep -w  16003 | sed -r 's#.* (.*)/.*#\1#'`
	echo "Stopping adminServer..."
	kill -9 `netstat -nlp | grep -w  14002 | sed -r 's#.* (.*)/.*#\1#'`
	;;
status)
	echo "Admin server is: $(serverstatus $ADMIN_PORT)"
	echo "EJB server is: $(serverstatus $EJB_PORT)"
	echo "Portal server is: $(serverstatus $PORTAL_PORT)"
	;;
setup)
        sleep 120
	echo y | bash /opt/SBM764/bin/setupSBM.sh -c all && tail -f /dev/null
        ;;
*)
	usage
	exit 1
	;;
esac

exit 0
