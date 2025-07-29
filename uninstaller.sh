#!/bin/bash

echo "#############################################"
echo "#### ArloCloud-RPi All-in-one uninstaller ###"
echo "#############################################"
echo

echo "Checking if the telegram-sync.service exists..."
if systemctl list-units --full --all | grep -q "telegram-sync.service"; then
    echo "Systemd service found. Proceeding to disable and remove..."

    if sudo systemctl stop telegram-sync.service && \
       sudo systemctl disable telegram-sync.service && \
       sudo rm -f /etc/systemd/system/telegram-sync.service && \
       sudo systemctl daemon-reload; then
        echo "Systemd service removed successfully."
    else
        echo "Failed to remove systemd service."
        exit 1
    fi
else
    echo "Systemd service not found. Skipping removal..."
fi

echo
echo "#############################################"
echo

echo "Checking if 'dwc2' is present in /etc/modules and /boot/config.txt..."

if grep -q "dwc2" /etc/modules; then
    echo "'dwc2' found in /etc/modules. Proceeding to remove..."
    if sudo sed -i '/dwc2/d' /etc/modules; then
        echo "'dwc2' removed from /etc/modules successfully."
    else
        echo "Failed to remove 'dwc2' from /etc/modules."
        exit 1
    fi
else
    echo "'dwc2' not found in /etc/modules. Skipping removal."
fi

if grep -q "dtoverlay=dwc2" /boot/config.txt; then
    echo "'dtoverlay=dwc2' found in /boot/config.txt. Proceeding to remove..."
    if sudo sed -i '/dtoverlay=dwc2/d' /boot/config.txt; then
        echo "'dtoverlay=dwc2' removed from /boot/config.txt successfully."
    else
        echo "Failed to remove 'dtoverlay=dwc2' from /boot/config.txt."
        exit 1
    fi
else
    echo "'dtoverlay=dwc2' not found in /boot/config.txt. Skipping removal."
fi

echo
echo "#############################################"
echo

echo "Removing ARLO image file and mount folders..."

if mountpoint -q /mnt/arlo; then
    sudo umount /mnt/arlo || { echo "Failed to unmount /mnt/arlo"; exit 1; }
fi

if sudo rm -rf /mnt/arlo && rm -f /arlo.bin && sudo rm -rf /mnt/ArloExposed; then
    echo "ARLO image and folders removed successfully."
else
    echo "Failed to remove ARLO image or mount folders."
    exit 1
fi

echo
echo "#############################################"
echo

echo "Checking if cron jobs exist..."

if crontab -l | grep -vE "@reboot sudo sh $(pwd)/enable_mass_storage.sh [0-9]+" | crontab - && \
   crontab -l | grep -vE "\\*/1 \\* \\* \\* \\* sudo /bin/bash $(pwd)/sync_clips.sh" | crontab - && \
   crontab -l | grep -vE "0 0 \\* \\* \\* sudo /bin/bash $(pwd)/cleanup_clips.sh" | crontab - ; then
    echo "All cron jobs found and removed."
else
    echo "One or more cron jobs not found. Skipping removal."
    exit 1
fi

crontab -l

echo
echo "#############################################"
echo

echo "Removing all ArloCloud-RPi related files (including this uninstaller)..."

if [ $(basename "$(pwd)") == "ArloCloud-RPi" ]; then
    
    if rm -rf $(pwd); then
        echo "All config files removed successfully."
    else
        echo "Failed to remove config files."
        exit 1
    fi
else
    echo "You are not in ArloCloud-RPi."
    exit 1
fi

echo
echo "#############################################"
echo

echo "All tasks completed successfully. Rebooting..."

sudo reboot now
