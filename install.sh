#!/bin/bash

mkdir -p ~/piTVstation/{scripts,videos,commercials,backups}

wget -P ~/ "https://github.com/JonVega/piTVstation/archive/refs/heads/master.zip"
unzip -jo ~/master.zip -d piTVstation/scripts/
rm ~/master.zip
sudo chmod 755 ~/piTVstation/scripts/{createStopmarks.sh,piTVstation.sh}

sudo apt update
sudo apt -y upgrade
sudo apt -y install vlc mediainfo samba samba-common-bin

# smb server

samba_config_location="/etc/samba/smb.conf"

if grep -q "\[piTVstation\]" "$samba_config_location"; then
	echo "[piTVstation] smb config already exists in /etc/samba/smb.conf"
else
	echo "[piTVstation]" | sudo tee -a $samba_config_location
	echo "path = /home/$USER/" | sudo tee -a $samba_config_location
	echo "writeable = yes" | sudo tee -a $samba_config_location
	echo "browseable = yes" | sudo tee -a $samba_config_location
	echo "public = no" | sudo tee -a $samba_config_location
	echo "---------------------------------------------"
	sudo smbpasswd -a $USER
	sudo systemctl restart smbd
fi

piTVstation_service_location="/etc/systemd/system/piTVstation.service"

if [ -e $piTVstation_service_location ]; then
	echo "piTVstation service already exists in $piTVstation_service_location"
else
	echo "[Unit]" | sudo tee -a $piTVstation_service_location
	echo "Description=Runs piTVStation script forever" | sudo tee -a $piTVstation_service_location
	echo "After=multi-user.target" | sudo tee -a $piTVstation_service_location
	echo "" | sudo tee -a $piTVstation_service_location
	echo "[Service]" | sudo tee -a $piTVstation_service_location
	echo "Type=simple" | sudo tee -a $piTVstation_service_location
	echo "Restart=on-failure" | sudo tee -a $piTVstation_service_location
	echo "User=$USER" | sudo tee -a $piTVstation_service_location
	echo "ExecStart=/home/$USER/piTVstation/scripts/piTVstation.sh" | sudo tee -a $piTVstation_service_location
	echo "" | sudo tee -a $piTVstation_service_location
	echo "[Install]" | sudo tee -a $piTVstation_service_location
	echo "WantedBy=multi-user.target" | sudo tee -a $piTVstation_service_location
	
	sudo chmod 644 $piTVstation_service_location
	sudo systemctl daemon-reload
	sudo systemctl enable piTVstation.service
fi