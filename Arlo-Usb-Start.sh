#!/bin/bash

################################################################# Logfile

LOG_FILE="$(pwd)/arlo_usb_start.log"

if [ -f "$LOG_FILE" ]; then
    > "$LOG_FILE"
else
    touch "$LOG_FILE"
fi

echo "LogFile SUCCESS - 1/6" >> "$LOG_FILE"

################################################################# ARGS

# Bad MaxPower
if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 100 ] || [ "$1" -gt 900 ]; then
    echo "Usage: $0 <max_power> <TelYes|TelNo> [api_token] [chat_id]"
    echo "Invalid max_power value. It must be a number between 100 and 900."
    echo "MAXPOWER ERROR - 2/6" >> "$LOG_FILE"
    exit 1
fi

MAX_POWER=$1
TEL_OPTION=$2

if [ "$TEL_OPTION" != "TelYes" ] && [ "$TEL_OPTION" != "TelNo" ]; then
    echo "Usage: $0 <max_power> <TelYes|TelNo> [api_token] [chat_id]"
    echo "Invalid option for TelYes|TelNo, run the script again"
    echo "TELOPTION ERROR - 2/6" >> "$LOG_FILE"
    exit 1
fi

if [ "$TEL_OPTION" == "TelYes" ]; then
    if [ -z "$3" ] || [ -z "$4" ]; then
        echo "Usage: $0 <max_power> TelYes <api_token> <chat_id>"
        echo "Invalid option for TelYes, run the script again"
        echo "TELYES ERROR - 2/6" >> "$LOG_FILE"
        exit 1
    fi

    SERVICE_FILE=/etc/systemd/system/telegram-sync.service

    API_TOKEN=$3
    CHAT_ID=$4

    cat <<EOF > $SERVICE_FILE
[Unit]
Description=Telegram Video Sync Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 $(pwd)/telegram-sync.py $API_TOKEN $CHAT_ID
WorkingDirectory=$(pwd)
#User=root
#Restart=always
#Environment=PATH=/usr/bin:/usr/local/bin
#Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable telegram-sync.service
    systemctl start telegram-sync.service
    
    echo "MAX_POWER + TELYES ARGS SUCCESS - 2/6" >> "$LOG_FILE"

else
    rm -f $(pwd)/telegram-sync.py
    echo "MAX_POWER + TELNO SUCCESS - 2/6" >> "$LOG_FILE"
fi

################################################################# Dependencies

is_installed() {
    dpkg -l "$1" &> /dev/null
}

dependencies=(bash findutils util-linux rsync grep coreutils procps kmod)

for package in "${dependencies[@]}"; do
    if ! is_installed "$package"; then
        echo "Dependencies ERROR: $package - 3/6">> "$LOG_FILE"
        exit 1
    fi
done

echo "Dependencies SUCCESS - 3/6">> "$LOG_FILE"

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

# Log the success message
echo "DWC2 SUCCESS - 4/6" >> "$LOG_FILE"

################################################################# Storage

ARLO_IMG_FILE="$(pwd)/arlo.bin"     # Define the ARLO image file and its size
ARLO_IMG_SIZE=31457280

# Function to calculate the offset of the first partition in the image file
function first_partition_offset () {
  local filename="$1"       # Get the filename from the first argument
  local size_in_bytes       # Variable to store the size in bytes
  local size_in_sectors     # Variable to store the size in sectors
  local sector_size         # Variable to store the sector size
  local partition_start_sector   # Variable to store the start sector of the partition

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
  local mountpoint="$(pwd)/$name"
  if [ ! -e "$mountpoint" ]
  then
    mkdir "$mountpoint"
  fi
}

add_drive "arlo" "ARLO" "$ARLO_IMG_SIZE" "$ARLO_IMG_FILE" 

echo "Storage IMG SUCCESS - 5/6" >> "$LOG_FILE"

################################################################# Cronjob

init_mass_storage="@reboot sudo sh $(pwd)/enable_mass_storage.sh $MAX_POWER"
sync_clip_interval="*/1 * * * * sudo /bin/bash $(pwd)/sync_clips.sh"
cleanup_clips_interval="0 0 * * * sudo /bin/bash $(pwd)/cleanup_clips.sh"

# Add init_mass_storage to crontab
( crontab -l 2>/dev/null | cat;  echo "$init_mass_storage" ) | crontab - \
    || { echo "Failed to add init_mass_storage to crontab" >> "$LOG_FILE"; exit 1; }

# Add sync_clip_interval to crontab
( crontab -l 2>/dev/null | cat;  echo "$sync_clip_interval" ) | crontab - \
    || { echo "Failed to add sync_clip_interval to crontab" >> "$LOG_FILE"; exit 1; }

# Add cleanup_clips_interval to crontab
( crontab -l 2>/dev/null | cat;  echo "$cleanup_clips_interval" ) | crontab - \
    || { echo "Failed to add cleanup_clips_interval to crontab" >> "$LOG_FILE"; exit 1; }

# Log the success message
echo "Cronjob SUCCESS - 6/6" >> "$LOG_FILE"

#################################################################

echo "Script finished, rebooting. Check log file for further informations."
sudo reboot now
