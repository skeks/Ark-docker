#!/usr/bin/env bash
echo "###########################################################################"
echo "# Ark Server - " `date`
echo "# UID $ARK_UID - GID $ARK_GID"
echo "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

function stop {
	if [ ${BACKUPONSTOP} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks)" ]; then
		echo "[Backup on stop]"
		arkmanager backup
	fi
	if [ ${WARNONSTOP} -eq 1 ];then 
	    arkmanager stop --warn
	else
	    arkmanager stop
	fi
	exit
}

# Change working directory to /ark to allow relative path
cd /ark

# Add a template directory to store the last version of config file
[ ! -d /ark/template ] && mkdir /ark/template
# We overwrite the template file each time
cp /home/steam/arkmanager.cfg /ark/template/arkmanager.cfg
cp /home/steam/crontab /ark/template/crontab
# Creating directory tree && symbolic link
[ ! -f /ark/arkmanager.cfg ] && cp /home/steam/arkmanager.cfg /ark/arkmanager.cfg
[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/staging ] && mkdir /ark/staging
[ ! -L /ark/Game.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/Game.ini Game.ini
[ ! -L /ark/GameUserSettings.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini GameUserSettings.ini
[ ! -f /ark/crontab ] && cp /ark/template/crontab /ark/crontab

if [ ! -d /ark/server  ] || [ ! -f /ark/server/version.txt ];then
	echo "No game files found. Installing..."
	mkdir -p /ark/server/ShooterGame/Saved/SavedArks
	mkdir -p /ark/server/ShooterGame/Content/Mods
	mkdir -p /ark/server/ShooterGame/Binaries/Linux/
	touch /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer
	arkmanager install
	# Create mod dir
else
	if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks/)" ]; then
		echo "[Backup]"
		arkmanager backup
	fi
fi

# Installing crontab for user steam
echo "Loading crontab..."
cat /ark/crontab | crontab -

# Copy env variables to arkmanager.cfg file. Prevents loss of config during automated updates
sed -i "s/ark_SessionName=.*/ark_SessionName=\"${SESSIONNAME}\"/g" /ark/arkmanager.cfg
sed -i "s/serverMap=.*/serverMap=${SERVERMAP}/g" /ark/arkmanager.cfg
sed -i "s/ark_ServerPassword=.*/ark_ServerPassword=${SERVERPASSWORD}/g" /ark/arkmanager.cfg
sed -i "s/ark_ServerAdminPassword=.*/ark_ServerAdminPassword=${ADMINPASSWORD}/g" /ark/arkmanager.cfg
sed -i "s/ark_MaxPlayers=.*/ark_MaxPlayers=${MAX_PLAYERS}/g" /ark/arkmanager.cfg
sed -i "s/ark_QueryPort=.*/ark_QueryPort=${SERVERPORT}/g" /ark/arkmanager.cfg
sed -i "s/ark_Port=.*/ark_Port=${STEAMPORT}/g" /ark/arkmanager.cfg
sed -i "s/ark_RCONPort=.*/ark_RCONPort=${RCONPORT}/g" /ark/arkmanager.cfg

# Launching ark server
if [ $UPDATEONSTART -eq 0 ]; then
	arkmanager start -noautoupdate
else
	arkmanager start
fi


# Stop server in case of signal INT or TERM
echo "Waiting..."
trap stop INT
trap stop TERM

read < /tmp/FIFO &
wait
