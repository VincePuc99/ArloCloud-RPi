#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOG_FILE="$SCRIPT_DIR/arlo_usb_uninstaller.log"

echo "#############################################"
echo "#### ArloCloud-RPi All-in-one uninstaller ###"
echo "#############################################"
echo

############################################# LogFile

if [ -f "$LOG_FILE" ]; then
    > "$LOG_FILE"
else
    touch "$LOG_FILE"
fi

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

#############################################

log "Checking if 'dwc2' is present in /etc/modules and /boot/config.txt..."

if grep -q "dwc2" /etc/modules; then
    log "'dwc2' found in /etc/modules. Proceeding to remove..."
    if sudo sed -i '/dwc2/d' /etc/modules; then
        log "'dwc2' removed from /etc/modules successfully."
    else
        log "Failed to remove 'dwc2' from /etc/modules."
        exit 1
    fi
else
    log "'dwc2' not found in /etc/modules. Skipping removal."
fi

echo

BOOT_CONFIG=""

echo "Getting config.txt location..."
if [ -f /boot/firmware/config.txt ]; then
    BOOT_CONFIG="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    BOOT_CONFIG="/boot/config.txt"
else
    log "BOOT CONFIG NOT FOUND - 5/7"
    exit 1
fi

if grep -q "dtoverlay=dwc2" "$BOOT_CONFIG"; then
    log "'dtoverlay=dwc2' found in $BOOT_CONFIG. Proceeding to remove..."
    if sudo sed -i '/dtoverlay=dwc2/d' "$BOOT_CONFIG"; then
        log "'dtoverlay=dwc2' removed from $BOOT_CONFIG successfully."
    else
        log "Failed to remove 'dtoverlay=dwc2' from $BOOT_CONFIG."
        exit 1
    fi
else
    log "'dtoverlay=dwc2' not found in $BOOT_CONFIG. Skipping removal."
fi

echo
echo "#############################################"
echo

ARLO_IMG_FILE="/arlo.bin" 
ARLO_IMG_MOUNT_POINT="$SCRIPT_DIR/arlo" 
ARLO_EXPOSED_MOUNT_POINT="$SCRIPT_DIR/ArloExposed" 

log "Removing ARLO image file and mount folders..."

if mountpoint -q "$ARLO_IMG_MOUNT_POINT"; then
    sudo umount "$ARLO_IMG_MOUNT_POINT" || { log "Failed to unmount $ARLO_IMG_MOUNT_POINT"; exit 1; }
fi

if sudo rm -rf "$ARLO_IMG_MOUNT_POINT" && rm -f "$ARLO_IMG_FILE" && sudo rm -rf "$ARLO_EXPOSED_MOUNT_POINT"; then
    log "ARLO image and folders removed successfully."
else
    log "Failed to remove ARLO image or mount folders."
    exit 1
fi

echo
echo "#############################################"
echo

log "Checking if cron jobs exist..."

if crontab -l | grep -vE "@reboot sudo sh $SCRIPT_DIR/enable_mass_storage.sh [0-9]+" | crontab - && \
   crontab -l | grep -vE "\\*/1 \\* \\* \\* \\* sudo /bin/bash $SCRIPT_DIR/sync_clips.sh" | crontab - ; then
   log "All cron jobs found and removed."
else
    log "One or more cron jobs not found. Skipping removal."
    exit 1
fi

echo
echo "#############################################"
echo

log "Removing all ArloCloud-RPi related files (including this uninstaller)..."

if [ $(basename "$SCRIPT_DIR") == "ArloCloud-RPi" ]; then
    
    if rm -rf $SCRIPT_DIR; then
        echo "All config files removed successfully."
    else
        log "Failed to remove config files."
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
