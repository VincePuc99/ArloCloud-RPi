#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#################################################################### Check if sync_clips process already exist

for pid in $(pidof -x sync_clips.sh); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : Process is already running"
        exit 1
    fi
done

#################################################################### Offset calculation

function first_partition_offset () {
  local filename="$1"
  local size_in_bytes
  local size_in_sectors
  local sector_size
  local partition_start_sector

  size_in_bytes=$(sfdisk -l -o Size -q --bytes "$1" | tail -1)
  size_in_sectors=$(sfdisk -l -o Sectors -q "$1" | tail -1)
  sector_size=$(( size_in_bytes / size_in_sectors ))
  partition_start_sector=$(sfdisk -l -o Start -q "$1" | tail -1)

  echo $(( partition_start_sector * sector_size ))
}

#################################################################### Mount/Sync Section

ARLO_IMG_FILE="/arlo.bin" 
ARLO_IMG_MOUNT_POINT="$SCRIPT_DIR/arlo" 
ARLO_EXPOSED_MOUNT_POINT="$SCRIPT_DIR/ArloExposed" 

umount "$ARLO_IMG_MOUNT_POINT" || true 

partition_offset=$(first_partition_offset "$ARLO_IMG_FILE")

loopdev=$(losetup -o "$partition_offset" -f --show "$ARLO_IMG_FILE")

mount "$loopdev" "$ARLO_IMG_MOUNT_POINT"

mkdir -p "$ARLO_EXPOSED_MOUNT_POINT"   # Create the directory if it doesn't exist

rsync -avu --delete --inplace "$ARLO_IMG_MOUNT_POINT" "$ARLO_EXPOSED_MOUNT_POINT"

umount "$ARLO_IMG_MOUNT_POINT" || true

losetup -d "$loopdev"
