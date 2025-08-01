<p align="center">
<img align="center" height="200" src="https://github.com/user-attachments/assets/5ec431a6-60b9-4f2e-b06e-44166ed7320d" />
</p>

# Arlo Self Hosted Cloud-RPi Setup

![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Raspberry Pi](https://img.shields.io/badge/-RaspberryPi-C51A4A?style=for-the-badge&logo=Raspberry-Pi)
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)

### Instead of relying on Arlo's cloud service, you can use a Raspberry Pi to store your videos locally and access them virtually everywhere!<br />

This setup lets you store every videos on your own Raspberry Pi. All you need is a Pi and an SD card. <br />

Once set up, your Pi connects directly to the Arlo base station, so you can access and store all your footage locally. <br />
Then you can share all your footage with your preferred method, Google Drive, Samba, Plex, virtually everything that can show videos! <br />

If you just want an Arlo’s cloud storage DIY alternative then ArloCloud-RPi is for you! <br />

The script enables a virtual USB storage of 30GB and sets up a crontab to synchronize clips between<br /> the virtual USB and an exposed folder (`./ArloExposed` inside the cloned `/ArloCloud-RPi`).<br />
You need to access this folder in order to view your clips on your preferred service.

#### ⚠️ WARNING ⚠️
Two directories will be created in `/ArloCloud-RPi` - `./arlo` and `./ArloExposed`.<br />
To avoid data corruption, DO NOT ALTER the `./arlo` one. It's a mount point for `sync_clips.sh`.<br />

Any other OS's / Distros are untested mainly due to `/boot/config.txt` position.

Tested on:
- Lexar 128GB SD Card
- [RPi-4B 8GB](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) and [RPi-Zero2W](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/)
- Latest [DietPi](https://dietpi.com/)
- Arlo Pro 2 - Arlo Pro 3 Floodlight / Base station [VMB4500r2](https://www.arlo.com/en_fi/support/faq/000062284/What-is-the-difference-between-each-Arlo-SmartHub-and-base-station) Latest Firmware.

## What you need

- A root user account

- A minimum of 64GB SD card

- For RPi Zero/Zero2W:
  - Connect the USB cable to the middle port from the RPi (Without the PWR label) to the USB of the station, Arlo base station itself is enough to power the Raspbery Pi.

- For others RPi's:
  - Connect the USB cable to any USB port of the RPi, you will need an external power source.
 
### Dependencies
The scripts require the following packages:<br />
`git` - `findutils` - `rsync`

The `arlo_usb_installer.sh` script will automatically check these dependencies.<br />
If they are not already installed the program will exit resulting in an error in `arlo_usb_installer.log`.
 
## Installation

### Cloning the Repository
To clone this repository, use the following command:

```sh
git clone https://github.com/VincePuc99/ArloCloud-RPi.git
```

### Permissions

```sh
cd ArloCloud-RPi
```
```sh
sudo chmod +x *
```

## Usage

```sh
sudo ./arlo_usb_installer.sh <max_power>
```
Where <max_power> is:

- `500` for Raspberry Pi 4B
- `200` for Raspberry Pi Zero 2
- `100` for Raspberry Pi Zero

Example for Raspberry Pi 4B:
```
sudo ./arlo_usb_installer.sh 500
```

After running `arlo_usb_installer.sh`, the Raspberry Pi will reboot.<br />

Upon reboot, check the connection to the base in Arlo Secure App™. It should look like the image below.

<img height="200" src="https://github.com/user-attachments/assets/d2842741-3aa3-4ed1-bdf5-b9e80154231c" />

## Uninstallation

To completely uninstall `ArloCloud-RPi`, run the following command:

```
sudo ./uninstaller.sh
```
This command will remove the USB image file, all mount points located inside `/ArloCloud-RPi` main folder, <br />
all files cloned with `git clone`, all crontab-related tasks and `dwc2` from `/etc/modules`-`/boot/config.txt`.<br />

Once the uninstaller has finished, the system will reboot.<br />
Afterward, check the connection to the base in Arlo Secure App™. It should look like the image below.

#### ⚠️ WARNING ⚠️
All saved clip in the `/ArloCloud-RPi` mount points (like `./arlo` and `./ArloExposed`) will be removed.<br />
Backup your data before proceeding!

<img height="200" src="https://github.com/user-attachments/assets/bd331990-24a9-488d-82bf-dba40d6eb6c5" />

## Documentation

- `arlo_usb_installer.sh` - This script installs necessary dependencies and runs the other scripts in the correct order. It ensures that the system is properly set up for USB mass storage and clip management.

- `enable_mass_storage.sh` - Enables USB mass storage with the specified maximum power.

- `sync_clips.sh` - Synchronizes clips from the USB storage to a shared directory. Ensures that the mount point is properly managed to avoid data corruption.

- `arlo_usb_installer.log` - Will be created on first run inside `ArloCloud-RPi` Main folder. Check it for any issue.

- `uninstaller.sh` - Uninstaller to remove every trace of `ArloCloud-RPi`.

## License
This project is licensed under the MIT License.
