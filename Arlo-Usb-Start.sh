#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

################################################################# Logfile

LOG_FILE="$SCRIPT_DIR/arlo_usb_start.log"

if [ -f "$LOG_FILE" ]; then
    > "$LOG_FILE"
else
    touch "$LOG_FILE"
fi

echo "LogFile SUCCESS - 1/7" >> "$LOG_FILE"

################################################################# MAX_POWER Control

if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 100 ] || [ "$1" -gt 900 ]; then
    echo "Usage: $0 <max_power>"
    echo "Invalid max_power value. It must be a number between 100 and 900."
    echo "MAXPOWER ERROR - 2/6" >> "$LOG_FILE"
    exit 1
fi

echo "MaxPower SUCCESS - 2/7" >> "$LOG_FILE"

MAX_POWER=$1

################################################################# Free Space check

FREE_SPACE_KB=$(df / | tail -1 | awk '{print $4}')

if [ "$FREE_SPACE_KB" -lt $((35 * 1024 * 1024)) ]; then
    echo "Error: Less than 35 GB available."
    echo "FREE_SPACE ERROR - 3/7" >> "$LOG_FILE"
    exit 1
fi

################################################################# Dependencies

is_installed() {
    dpkg -l "$1" &> /dev/null
}

dependencies=(findutils rsync)

for package in "${dependencies[@]}"; do
    if ! is_installed "$package"; then
        echo "Dependencies ERROR: $package - 3/6">> "$LOG_FILE"
        exit 1
    fi
done

echo "Dependencies SUCCESS - 4/7">> "$LOG_FILE"

################################################################# DWC2

# Append "dwc2" to /etc/modules
if sudo sh -c 'echo "dwc2" >> /etc/modules'; then
    echo "Successfully appended 'dwc2' to /etc/modules" >> "$LOG_FILE"
else
    echo "Failed to append 'dwc2' to /etc/modules" >> "$LOG_FILE"
    exit 1
fi

# Append "dtoverlay=dwc2" to /boot/config.txt
if sudo sh -c 'echo "dtoverlay=dwc2" >> /boot/config.txt'; then
    echo "Successfully appended 'dtoverlay=dwc2' to /boot/config.txt" >> "$LOG_FILE"
else
    echo "Failed to append 'dtoverlay=dwc2' to /boot/config.txt" >> "$LOG_FILE"
    exit 1
fi

echo "DWC2 SUCCESS - 5/7" >> "$LOG_FILE"

################################################################# Storage

ARLO_IMG_FILE="$SCRIPT_DIR/arlo.bin"     # Define the ARLO image file and its size
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

echo "Storage IMG SUCCESS - 6/7" >> "$LOG_FILE"

################################################################# Cronjob

init_mass_storage="@reboot sudo sh $SCRIPT_DIR/enable_mass_storage.sh $MAX_POWER"
sync_clip_interval="*/1 * * * * sudo /bin/bash $SCRIPT_DIR/sync_clips.sh"
cleanup_clips_interval="0 0 * * * sudo /bin/bash $SCRIPT_DIR/cleanup_clips.sh"

( crontab -l 2>/dev/null | cat;  echo "$init_mass_storage" ) | crontab - \
    || { echo "Failed to add init_mass_storage to crontab" >> "$LOG_FILE"; exit 1; }

( crontab -l 2>/dev/null | cat;  echo "$sync_clip_interval" ) | crontab - \
    || { echo "Failed to add sync_clip_interval to crontab" >> "$LOG_FILE"; exit 1; }

( crontab -l 2>/dev/null | cat;  echo "$cleanup_clips_interval" ) | crontab - \
    || { echo "Failed to add cleanup_clips_interval to crontab" >> "$LOG_FILE"; exit 1; }

echo "Cronjob SUCCESS - 7/7" >> "$LOG_FILE"

#################################################################

echo "Script finished, rebooting. Check log file for further informations."
sudo reboot now
