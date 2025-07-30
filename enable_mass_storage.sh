#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <max_power>"
    exit 1
fi

max_power=$1

usb_gadget="/sys/kernel/config/usb_gadget"  #Gadget DIR
gadget="arlo"                               #Gadget Name
gadget_root="$usb_gadget/$gadget"           #Gadget complete Path
img_file="$(pwd)/arlo.bin"                  #IMG File Path
lang=0x409                                  #English Lang Code
cfg=c                                       #Config Name

modprobe libcomposite                       #Load Lib For Gadgets

mkdir -p "$gadget_root/configs/$cfg.1"      #Create gadget config dir

#USB Gadget Specs
echo 0x1d6b > "$gadget_root/idVendor"  # Linux Foundation
echo 0x0104 > "$gadget_root/idProduct" # Composite Gadget
echo 0x0100 > "$gadget_root/bcdDevice" # v1.0.0
echo 0x0200 > "$gadget_root/bcdUSB"    # USB 2.0

#More configs for gadget
mkdir -p "$gadget_root/strings/$lang"
mkdir -p "$gadget_root/configs/$cfg.1/strings/$lang"

#Cpu serial number to gadget serial number
echo "$(grep Serial /proc/cpuinfo | awk '{print $3}')" > "$gadget_root/strings/$lang/serialnumber"

#Productor Gadget
echo "TDD" > "$gadget_root/strings/$lang/manufacturer"

#Product name
echo "Composite Drive" > "$gadget_root/strings/$lang/product"

#Description of gadget 
echo "Raspberry Pi Foundation" > "$gadget_root/configs/$cfg.1/strings/$lang/configuration"

#Set max power
echo "$max_power" > "$gadget_root/configs/$cfg.1/MaxPower"

#Main dir for gadget data
mkdir -p "$gadget_root/functions/mass_storage.0"

#IMG as file for archiving data
echo "$img_file" > "$gadget_root/functions/mass_storage.0/lun.0/file"

#Device name
echo "Arlo RPi $(du -h $img_file | awk '{print $1}')" > "$gadget_root/functions/mass_storage.0/lun.0/inquiry_string"

#simlink
ln -sf "$gadget_root/functions/mass_storage.0" "$gadget_root/configs/$cfg.1"

#Gadget activation
ls /sys/class/udc > "$gadget_root/UDC"
