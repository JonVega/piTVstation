#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variables that you should change to setup how you like  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

piTVstation_Directory_Location="$HOME/piTVstation"

# change this if you don't want your user name to be your password to access SMB
samba_server_password="$USER"

# --------------------------------------------------------------------------

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# !!! ADVANCE - ONLY ALTER BELOW IF YOU KNOW WHAT YOU'RE DOING !!!  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

piTVstation_latest_release_tag_name=$(curl -s https://api.github.com/repos/JonVega/piTVstation/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')


echo "        // Creating Directories"
mkdir $piTVstation_Directory_Location

piTVstation_directories=("$piTVstation_Directory_Location/scripts" "$piTVstation_Directory_Location/videos" "$piTVstation_Directory_Location/commercials" "$piTVstation_Directory_Location/backups" "$piTVstation_Directory_Location/assets")

for piTVstation_directory in "${piTVstation_directories[@]}"; do
    case $([ -d "$piTVstation_directory" ]; echo $?) in
        0)  # Directory exists
            echo "        Skipping $piTVstation_directory since it exists"
            ;;
        1)  # Directory does not exist
            mkdir $piTVstation_directory
            echo "        Created $piTVstation_directory"
            ;;
        *)
            echo "ERROR CHECKING $piTVstation_directory"
            exit 1;
            ;;
    esac
done

echo "        // Grabbing piTVstation ZIP File"
wget -P ~/ "https://github.com/JonVega/piTVstation/archive/refs/tags/$piTVstation_latest_release_tag_name.zip"

echo "        // Unzipping piTVstation"
unzip -jo ~/$piTVstation_latest_release_tag_name.zip -d $piTVstation_Directory_Location/scripts/
mv $piTVstation_Directory_Location/scripts/RCA_Indian_Head_test_pattern.JPG $piTVstation_Directory_Location/assets/

echo "        // Deleting Downloaded piTVstation ZIP File"
rm ~/$piTVstation_latest_release_tag_name.zip

echo "        // Making Scripts Executable With chmod"
sudo chmod 755 $piTVstation_Directory_Location/scripts/{createStopmarks.sh,piTVstation.sh}

echo "        // Updating Pi And Downloading VLC, Mediainfo, And SMB Server"
sudo apt update
sudo apt -y upgrade
sudo apt -y install vlc mediainfo samba samba-common-bin

# smb server configuration
samba_config_location="/etc/samba/smb.conf"

echo "        // Setting Up SMB Server"

if grep -q "\[piTVstation\]" "$samba_config_location"; then
	echo "       // piTVstation smb config already exists in /etc/samba/smb.conf"
else
	echo "[piTVstation]" | sudo tee -a $samba_config_location
	echo "path = /home/$USER/" | sudo tee -a $samba_config_location
	echo "writeable = yes" | sudo tee -a $samba_config_location
	echo "browseable = yes" | sudo tee -a $samba_config_location
	echo "public = no" | sudo tee -a $samba_config_location
	echo "---------------------------------------------"
	echo -e "$samba_server_password\n$samba_server_password" | sudo smbpasswd -s -a $USER
	sudo systemctl restart smbd
fi

# Make piTVstation start on boot
piTVstation_service_location="/etc/systemd/system/piTVstation.service"

echo "        // Making piTVstation Run On Startup"

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

echo "         // Yay! Completed Installation, Restarting..."
sudo shutdown -r now