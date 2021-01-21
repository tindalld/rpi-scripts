#!/bin/bash
echo "This setup script will prepare this device for Carbide CNC"
echo "update the package listing"

sudo apt-get update -y

echo "perform the system upgrades"

sudo apt-get full-upgrade -y

echo "install basic x server and desktop tools"
sudo apt-get install -y --no-install-recommends xserver-xorg 
sudo apt-get install -y --no-install-recommends xinit
sudo apt-get install -y --no-install-recommends raspberrypi-ui-mods lxsession
sudo apt-get install -y lightdm
sudo apt-get install -y pi-greeter
sudo apt-get install -y rpd-icons
sudo apt-get install -y gtk2-engines-clearlookspix
sudo apt-get install -y lxterminal

echo "install only the tools and packages to make carbide motion and the pi work."
echo "usbmount will all automounting usb sticks."
sudo apt-get install -y usbmount
echo "wmctrl allows an application to operate full screen even when it does not have that menu option."
sudo apt-get install -y wmctrl
echo "set up the system for network file shares"
DEBIAN_FRONTEND=noninteractive apt-get install -y --assume-yes samba samba-common-bin
sudo apt-mark manual samba
sudo cp -p /etc/samba/smb.conf smb.conf.bak

echo "setting up folders"
mkdir /home/pi/Carbide3d
mkdir /home/pi/Carbide3d/gcode
mkdir /home/pi/Carbide3d/usb
chown  1000.1000 /home/pi/Carbide3d
chown 1000.1000 /home/pi/Carbide3d/gcode
chown 1000.1000 /home/pi/Carbide3d/usb

echo "download and install Carbide Motion"
cd /home/pi/Carbide3d
curl -O -L https://motion-pi.us-east-1.linodeobjects.com/carbidemotion-530.deb
sudo apt-get install -q -y /home/pi/Carbide3d/carbidemotion-530.deb

echo "get config files from github"
mkdir /home/pi/Carbide3d/configs
cd /home/pi/Carbide3d/configs/
curl -O -L https://raw.githubusercontent.com/tindalld/rpi-scripts/main/smb.conf
curl -O -L https://raw.githubusercontent.
com/tindalld/rpi-scripts/main/rc.local
curl -O -L https://raw.githubusercontent.com/tindalld/rpi-scripts/main/carbidemotion.desktop
curl -O -L https://raw.githubusercontent.com/tindalld/rpi-scripts/main/launch-cm.c

echo "build the launcher applicaton"
sudo gcc -02 -Wall /home/pi/Carbide3d/configs/launch-cm.c -o /usr/bin/launch-cm

echo "copy config files to proper locations"

sudo cp /home/pi/Carbide3d/configs/smb.conf /etc/samba/smb.conf
sudo systemctl restart smbd
sudo cp /home/pi/Carbide3d/configs/carbidemotion.desktop /etc/xdg/autostart
sudo cp /home/pi/Carbide3d/configs/rc.local /etc/rc.local

echo "create mount namespaces for automounting USB Sticks"
sudo mkdir -p image/etc/systemd/system/systemd-udevd.service.d/
echo "[Service]" > image/etc/systemd/system/systemd-udevd.service.d/myoverride.conf
echo "MountFlags=shared" >> image/etc/systemd/system/systemd-udevd.service.d/myoverride.conf
echo "PrivateMounts=no" >> image/etc/systemd/system/systemd-udevd.service.d/myoverride.conf
# redirect the first USB stick to /gode/usb
echo "/dev/sda1        /home/pi/Carbide3d/usb   vfat	user,noauto,uid=1000    0      0" >> /etc/fstab

echo "install and enable realVNC server"
sudo apt-get install -y  realvnc-vnc-server

echo "clean download cache"
sudo apt-get clean

echo "output package listing"
sudo dpkg --list > pkglist.txt


echo "End of script....time to reboot"
seconds=5
(
for i in $(seq $seconds -1 1); do
	echo "$i seconds to reboot...";
	sleep 1;
done;
echo "rebooting now!") 
sudo reboot
