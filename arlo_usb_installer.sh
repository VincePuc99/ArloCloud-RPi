#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

################################################################# Logfile

LOG_FILE="$SCRIPT_DIR/arlo_usb_installer.log"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

if [ -f "$LOG_FILE" ]; then
    > "$LOG_FILE"
else
    touch "$LOG_FILE"
fi

log "LogFile SUCCESS - 1/7"

################################################################# MAX_POWER Control

if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 100 ] || [ "$1" -gt 900 ]; then
    log "Usage: $0 <max_power>"
    log "Invalid max_power value. It must be a number between 100 and 900."
    log "MAXPOWER ERROR - 2/7"
    exit 1
fi

log "MaxPower SUCCESS - 2/7"

MAX_POWER=$1

################################################################# Free Space check

FREE_SPACE_KB=$(df / | tail -1 | awk '{print $4}')

if [ "$FREE_SPACE_KB" -lt $((35 * 1024 * 1024)) ]; then
    log "Error: Less than 35 GB available."
    log "FREE_SPACE ERROR - 3/7"
    exit 1
fi

log "FREE_SPACE SUCCESS - 3/7"

################################################################# Dependencies

is_installed() {
    dpkg -s "$1" &>/dev/null
}

dependencies=(findutils rsync)

for package in "${dependencies[@]}"; do
    if ! is_installed "$package"; then
        log "Dependencies ERROR: $package - 4/7"
        exit 1
    fi
done

log "Dependencies SUCCESS - 4/7"

################################################################# DWC2

BOOT_CONFIG=""

# Detect correct boot config file
if [ -f /boot/firmware/config.txt ]; then
    BOOT_CONFIG="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    BOOT_CONFIG="/boot/config.txt"
else
    log "BOOT CONFIG NOT FOUND - 5/7"
    exit 1
fi

# Append dwc2 to /etc/modules if not already present
if ! grep -q "^dwc2$" /etc/modules 2>/dev/null; then
    echo "dwc2" | sudo tee -a /etc/modules > /dev/null
fi

# Append dtoverlay if not already present
if ! grep -q "dtoverlay=dwc2" "$BOOT_CONFIG"; then
    echo "dtoverlay=dwc2" | sudo tee -a "$BOOT_CONFIG" > /dev/null
    log "dtoverlay added to $BOOT_CONFIG"
else
    log "dtoverlay already present in $BOOT_CONFIG"
fi

log "DWC2 SUCCESS - 5/7"

################################################################# Storage

ARLO_IMG_FILE="/arlo.bin"     # Define the ARLO image file and its size (root path / mandatory)
ARLO_IMG_SIZE=31457280

# Function to calculate the offset of the first partition in the image file
function first_partition_offset () {
  local filename="$1"           # Get the filename from the first argument
  local size_in_bytes           # Variable to store the size in bytes
  local size_in_sectors         # Variable to store the size in sectors
  local sector_size             # Variable to store the sector size
  local partition_start_sector  # Variable to store the start sector of the partition

  size_in_bytes=$(sfdisk -l -o Size -q --bytes "$1" | tail -1)
  size_in_sectors=$(sfdisk -l -o Sectors -q "$1" | tail -1)
  sector_size=$(( size_in_bytes / size_in_sectors ))
  partition_start_sector=$(sfdisk -l -o Start -q "$1" | tail -1)

  echo $(( partition_start_sector * sector_size ))
}

function add_drive () { 

  local name="$1"
  local label="$2"
  local size="$3"
  local filename="$4"
  fallocate -l "$size"K "$filename"
  
  echo "type=c" | sfdisk "$filename" > /dev/null
  
  local partition_offset
  partition_offset=$(first_partition_offset "$filename")
  loopdev=$(losetup -o "$partition_offset" -f --show "$filename")
  mkfs.vfat "$loopdev" -F 32 -n "$label" > /dev/null 2>&1
  losetup -d "$loopdev"
  local mountpoint="$SCRIPT_DIR/$name"
  if [ ! -e "$mountpoint" ]
  then
    mkdir "$mountpoint"
  fi
}

add_drive "arlo" "ARLO" "$ARLO_IMG_SIZE" "$ARLO_IMG_FILE" 

log "Storage IMG SUCCESS - 6/7"

################################################################# Cronjob

init_mass_storage="@reboot sudo sh $SCRIPT_DIR/enable_mass_storage.sh $MAX_POWER"
sync_clip_interval="*/1 * * * * sudo /bin/bash $SCRIPT_DIR/sync_clips.sh"

( crontab -l 2>/dev/null | cat;  echo "$init_mass_storage" ) | crontab - \
    || { log "Failed to add init_mass_storage to crontab, 7/7 ERROR"; exit 1; }

( crontab -l 2>/dev/null | cat;  echo "$sync_clip_interval" ) | crontab - \
    || { log "Failed to add sync_clip_interval to crontab, 7/7 ERROR"; exit 1; }

log "Cronjob SUCCESS - 7/7"

#################################################################

echo "Script finished, rebooting. Check log file for further informations."
sudo reboot
