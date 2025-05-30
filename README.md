# Arlo Self Hosted Cloud-RPi Setup

![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![Telegram](https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)
![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![Raspberry Pi](https://img.shields.io/badge/-RaspberryPi-C51A4A?style=for-the-badge&logo=Raspberry-Pi)

### Instead of relying on Arlo's cloud service, you can use a Raspberry Pi to store your videos locally and access them virtually everywhere!<br />

This setup lets you store every videos on your own Raspberry Pi. All you need is a Pi and an SD card. <br />
Once set up, your Pi connects directly to the Arlo base station, so you can access and store all your footage locally. <br />
Then you can share all your footage with your preferred method, i'm using Telegram but it's up to you, Google Drive, Samba, One Drive, virtually everything that can show videos! <br />
If you just want an Arlo’s cloud storage DIY alternative then ArloCloud-RPi is for you! <br />

The scripts handle tasks such as enabling mass storage (30GB), synchronizing clips, cleaning up old clips and optionally create a service for synchronizing clips with a Telegram Bot. <br />
All clips are stored in `/mnt/ArloExposed`.<br />You need to access to this folder to expose them on your preferred service (Google Drive - Samba - Telegram - etc).

#### ⚠️ WARNING ⚠️
Two folders will be created in `/mnt` - `/arlo` and `/ArloExposed`.<br />To avoid data corruption, DO NOT ALTER the `/arlo` one. It's a mount point for `sync_clips.sh`.<br />

If using `Sync with Telegram Bot` double check your `[api_token]` & `[chat_id]`.<br />The program will not check them for you!<br />

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
 

<details>
  <summary><h3>Optional - Sync with Telegram Bot</h3></summary>

For security reasons, I'm using it in polling mode. This may be inefficient, but it is strongly recommended to avoid opening any ports or exposing your public IP to the global internet. I will not develop a solution based on webhooks.

This Python script `telegram-sync.py` monitors `/mnt/ArloExposed/arlo/` in recursive mode for new video files, calculate their hashes (for logging purpose), and sends them to your Telegram bot. It uses the bot's API token and the chat ID to send the videos.

For using it just add `TelYes` during the first setup.

If you choose `TelNo`, the `telegram-sync.py` file will be automatically deleted.

**Prerequisites for Telegram Sync**

- [➡️](https://www.python.org/downloads/) `Python3`
- [➡️](https://python-telegram-bot.org/) `python-telegram-bot`
- [➡️](https://core.telegram.org/bots#how-do-i-create-a-bot) `A Telegram bot with the API token` (created via BotFather)
- [➡️](https://t.me/userinfobot) `The chat ID of the Telegram chat` where the videos will be sent.

</details>

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
sudo ./Arlo-Usb-Start.sh <max_power> <TelYes|TelNo> [api_token] [chat_id]
```
Where <max_power> is:

- `500` for Raspberry Pi 4B
- `200` for Raspberry Pi Zero 2
- `100` for Raspberry Pi Zero

Example for Raspberry Pi 4B with Telegram Sync Enabled:
```
sudo ./Arlo-Usb-Start.sh 500 TelYes 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11 -zzzzzzzzzz
```
Example for Raspberry Pi 4B without Telegram Sync (`TelNo` will automatically delete `telegram-sync.py`):
```
sudo ./Arlo-Usb-Start.sh 500 TelNo
```

After running `Arlo-Usb-Start.sh`, the Raspberry Pi will reboot.<br />

Upon reboot, check the connection to the base in Arlo Secure App. It should look like the image below.

<img height="200" src="https://github.com/user-attachments/assets/d2842741-3aa3-4ed1-bdf5-b9e80154231c" />


## Documentation

- `Arlo-Usb-Start.sh` - This script installs necessary dependencies and runs the other scripts in the correct order. It ensures that the system is properly set up for USB mass storage and clip management. | Main script to start the setup process.

- `cleanup_clips.sh` - Cleans up old clips from the storage directory. By default, it removes clips older than 14 days.

- `enable_mass_storage.s` - Enables USB mass storage with the specified maximum power.

- `sync_clips.sh` - Synchronizes clips from the USB storage to a shared directory. Ensures that the mount point is properly managed to avoid data corruption.

- `arlo_usb_start.log` - Will be created on first run inside ArloUSB-AnyRP Main folder. Check it for any issue.

- `mp4_hashes.log` - (Optional) Logging file containing hashes of the videos, useful for telegram-sync.py.

- `telegram-sync.py` - (Optional) File service for synchronizing clips from the USB storage to a Telegram Bot.

### Dependencies
The scripts require the following packages:<br />
`git` - `bash` - `findutils` - `util-linux` - `rsync` - `grep` - `coreutils` - `procps` - `kmod`

The optional Telegram Sync script require the following packages:<br />
`python3` - `python-telegram-bot`

The Arlo-Usb-Start.sh script will automatically check these dependencies.<br />If they are not already installed the program will exit resulting in an error in LogFile.

## License
This project is licensed under the MIT License.
