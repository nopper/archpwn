#!/bin/bash

. /etc/rc.conf
. /etc/rc.d/functions
. /etc/rc.d/functions.d/cmdline
. /etc/chakra-hwdetect.conf



#
# CHECK KERNEL COMMANDLINE IF NONFREE DRIVERS
# HAVE BEEN ENABLED OR NOT...
#
NONFREE=`get_nonfree`

	[ -n "$NONFREE" ] || NONFREE="yes"

	case "$NONFREE" in

		yes)

		if [ -e "/tmp/nvidia-173xx" ] ; then
			printhl "Loading tainted kernel module: nvidia"
			modprobe nvidia &>/dev/null
	
			printhl "Setting up X.Org driver: nvidia"
			DRIVER_NVIDIA="Driver\t\"nvidia\""
			sed -i -e /'Section "Device"'/,/'EndSection'/s/'Driver.*'/$DRIVER_NVIDIA/g /etc/X11/xorg.conf

			# setup extra options
			sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"NoLogo\"    \"true\"\nEndSection"/g /etc/X11/xorg.conf

			# remove stuff we dont need
			sed -i '/^.*VBERestore.*/d' /etc/X11/xorg.conf
			sed -i '/^.*XAANoOffscreenPixmaps.*/d' /etc/X11/xorg.conf
			sed -i '/^.*AIGLX.*/d' /etc/X11/xorg.conf
			sed -i '/^.*GLcore.*/d' /etc/X11/xorg.conf
			sed -i '/^.*"DRI"    "true".*/d' /etc/X11/xorg.conf

		elif [ -e "/tmp/nvidia-96xx" ] ; then
			printhl "Loading tainted kernel module: nvidia"
			modprobe nvidia &>/dev/null
	
			printhl "Setting up X.Org driver: nvidia"
			DRIVER_NVIDIA="Driver\t\"nvidia\""
			sed -i -e /'Section "Device"'/,/'EndSection'/s/'Driver.*'/$DRIVER_NVIDIA/g /etc/X11/xorg.conf

			# setup extra options
			sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"NoLogo\"    \"true\"\nEndSection"/g /etc/X11/xorg.conf

			# remove stuff we dont need
			sed -i '/^.*VBERestore.*/d' /etc/X11/xorg.conf
			sed -i '/^.*XAANoOffscreenPixmaps.*/d' /etc/X11/xorg.conf
			sed -i '/^.*AIGLX.*/d' /etc/X11/xorg.conf
			sed -i '/^.*GLcore.*/d' /etc/X11/xorg.conf
			sed -i '/^.*"DRI"    "true".*/d' /etc/X11/xorg.conf

		elif [ -e "/tmp/nvidia" ] ; then
			printhl "Loading tainted kernel module: nvidia"
			modprobe nvidia &>/dev/null
	
			printhl "Setting up X.Org driver: nvidia"
			DRIVER_NVIDIA="Driver\t\"nvidia\""
			sed -i -e /'Section "Device"'/,/'EndSection'/s/'Driver.*'/$DRIVER_NVIDIA/g /etc/X11/xorg.conf
			
			# setup extra options
			#sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"NvAGP\"    \"1\"\nEndSection"/g /etc/X11/xorg.conf
			sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"NoLogo\"    \"true\"\nEndSection"/g /etc/X11/xorg.conf
			#sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"RenderAccel\"    \"true\"\nEndSection"/g /etc/X11/xorg.conf
			#sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"AddARGBVisuals\"    \"true\"\nEndSection"/g /etc/X11/xorg.conf
			#sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"AddARGBGLXVisuals\"    \"true\"\nEndSection"/g /etc/X11/xorg.conf
			#sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"AllowGLXWithComposite\"    \"true\"\nEndSection"/g /etc/X11/xorg.conf
			sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"DynamicTwinView\"    \"false\"\nEndSection"/g /etc/X11/xorg.conf

			# remove stuff we dont need
			sed -i '/^.*VBERestore.*/d' /etc/X11/xorg.conf
			sed -i '/^.*XAANoOffscreenPixmaps.*/d' /etc/X11/xorg.conf
			sed -i '/^.*AIGLX.*/d' /etc/X11/xorg.conf
			sed -i '/^.*GLcore.*/d' /etc/X11/xorg.conf
			sed -i '/^.*"DRI"    "true".*/d' /etc/X11/xorg.conf

		elif [ -e "/tmp/catalyst" ] ; then
			printhl "Loading tainted kernel module: fglrx"
			modprobe fglrx &>/dev/null
		
			printhl "Setting up X.Org driver: fglrx"
			DRIVER_ATI="Driver\t\"fglrx\""
			sed -i -e /'Section "Device"'/,/'EndSection'/s/'Driver.*'/$DRIVER_ATI/g /etc/X11/xorg.conf

			# setup DRI for ATI
			echo 'Section "DRI"' >> /etc/X11/xorg.conf
			echo '        Group  "video"' >> /etc/X11/xorg.conf
			echo '        Mode   0666' >> /etc/X11/xorg.conf
			echo 'EndSection' >> /etc/X11/xorg.conf
			echo ' ' >> /etc/X11/xorg.conf                       
                         
		else                   
			# we are not using a free driver, 
			echo 'Section "DRI"' >> /etc/X11/xorg.conf
			echo '        Group  "video"' >> /etc/X11/xorg.conf
			echo '        Mode   0666' >> /etc/X11/xorg.conf
			echo 'EndSection' >> /etc/X11/xorg.conf
			echo ' ' >> /etc/X11/xorg.conf
		fi                     
		;;

		*)

			# we are not using a free driver, so we add DRI stuff
			echo 'Section "DRI"' >> /etc/X11/xorg.conf
			echo '        Group  "video"' >> /etc/X11/xorg.conf
			echo '        Mode   0666' >> /etc/X11/xorg.conf
			echo 'EndSection' >> /etc/X11/xorg.conf
			echo ' ' >> /etc/X11/xorg.conf

		;;
	esac
