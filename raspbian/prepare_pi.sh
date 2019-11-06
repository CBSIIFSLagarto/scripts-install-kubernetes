#!/bin/sh

##############################################
# VARIABLES

CURRENT_TIMEZONE='America/Recife'	
XKBMODEL="abnt2"
XKBLAYOUT="br"


##############################################

echo "Setup keyboard [y/n]? "
read setupKeyboard

if [ $setupKeyboard == 'y' ]; then
	echo "KB MODEL [default is $XKBMODEL]? "	
	read MODEL
	if [ -z $MODEL ]; then
		echo "Use $XKBMODEL model"
	else
		XKBMODEL="$MODEL"
	fi


	echo "KB LAYOUT [default is $XKBLAYOUT]? "	
	read LAYOUT
	if [ -z $LAYOUT ]; then
		echo "Use $XKBLAYOUT layout"
	else
		XKBLAYOUT="$LAYOUT"
	fi

	sudo sed -i "s/^XKBMODEL.*/XKBMODEL=\"$XKBMODEL\"/g" /etc/default/keyboard &&\
	sudo sed -i "s/^XKBLAYOUT.*/XKBLAYOUT=\"$XKBLAYOUT\"/g" /etc/default/keyboard &&\
	sudo service keyboard-setup restart
fi


##############################################

echo "Set Hostname [leave blank to skip]: "
read answer
if [ -z $answer -a $answer != $(hostname) ]; then
	sudo hostnamectl set-hostname $answer
fi

##############################################


echo "Disable bluetooth (default=y)[y/n]: "
read bluetooth
if [ -z $bluetooth -o $bluetooth == 'y' ]; then
	echo 
	echo "**** disable bluetooth ****"
	echo 

	echo "dtoverlay=pi3-disable-bt" | sudo tee -a /boot/config.txt
	systemctl disable hciuart.service
	systemctl disable bluealsa.service
	systemctl disable bluetooth.service
fi

##############################################

clear

##############################################

echo "Set timezone (default=$CURRENT_TIMEZONE)[y/n]:"
read timezones
if [ -z $timezones ]; then
	# timedatectl list-timezones # show time zones
	sudo timedatectl set-timezone $(CURRENT_TIMEZONE)
elif [$timezones == 'n']; then
	echo "skipped"
else
	echo "Setting timezone to: $timezones"
	sudo timedatectl set-timezone $(timezones)
fi


##############################################

clear

##############################################

echo ***************************
echo \# HOSTNAME: $(hostname)
echo \# BLUETOOH $(systemctl status bluetooth.service | grep "Status")
echo Keyboard configuration:
cat /etc/default/keyboard
echo \# TIME ZONE: $(timedatectl)
echo \# Current date: $(date)
echo ***************************


echo 
echo "**** updating system ****"
echo 


apt-get update && \
	apt-get -y upgrade && \
	apt-get -y dist-upgrade && \ 
	apt-get update && \
	apt-get -y autoremove && \
	apt-get -y clean 



echo 
echo "**** disable swap ****"
echo 

swapoff -a
sudo systemctl disable dphys-swapfile.service

sudo dphys-swapfile swapoff && \
  sudo dphys-swapfile uninstall && \
  sudo update-rc.d dphys-swapfile remove

echo 
echo "**** enable cgroup ****"
echo 

echo Adding " cgroup_enable=cpuset cgroup_enable=memory" to /boot/cmdline.txt
cp /boot/cmdline.txt /boot/cmdline_backup.txt
echo "if you encounter problems, try changing cgroup_memory=1 to cgroup_enable=memory."
orig="$(head -n1 /boot/cmdline.txt) cgroup_enable=cpuset cgroup_memory=1"
echo $orig | sudo tee /boot/cmdline.txt
echo "gpu_mem=16" | sudo tee -a /boot/config.txt




echo 
echo "**** config network ****"
echo 

echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a  /etc/sysctl.conf
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl net.ipv4.ip_forward=1


echo 
echo "**** Please restart raspberry ****"
echo "**** sudo reboot ****"
echo 
