#!/bin/bash
#
#**************************************************************************
#   Copyright (C) 2008 Jan Mette                                          *
#   Copyright (C) 2009 Jan Mette and Phil Miller                          *
#   <jan[dot]mette[at]berlin[dot]de>                                      *
#   <philm[at]chakra-project[dot]org>                                     *
#                                                                         *
#   This script is free software; you can redistribute it and/or modify   *
#   it under the terms of the GNU General Public License as published by  *
#   the Free Software Foundation; either version 2 of the License, or     *
#   (at your option) any later version.                                   *
#                                                                         *
#   This program is distributed in the hope that it will be useful,       *
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
#   GNU General Public License for more details.                          *
#                                                                         *
#   You should have received a copy of the GNU General Public License     *
#   along with this program; if not, write to the                         *
#   Free Software Foundation, Inc.,                                       *
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.          *
#**************************************************************************



#
# source needed functions and configs
#
# rc.conf
. /etc/rc.conf
# for message stuff like printhl
. /etc/rc.d/functions
# for kernel cmdline parsing
. /etc/rc.d/functions.d/cmdline
# the main config
. /etc/chakra-hwdetect.conf

#
# CHECK KERNEL COMMANDLINE IF XDRIVER VALUE OR NONFREE DRIVERS
# HAVE BEEN ENABLED OR NOT...
#
	NONFREE=`get_nonfree`
	XDRIVER=`get_xdriver`

	[ -n "$XDRIVER" ] || XDRIVER="vesa"

	case "$XDRIVER" in

		vesa)

			NONFREE="no"
			#force vesa driver
			printhl "Setting up X.Org driver: vesa"
			XDRIVER_VAL="Driver\t\"vesa\""
			sed -i -e /'Section "Device"'/,/'EndSection'/s/'Driver.*'/$XDRIVER_VAL/g /etc/X11/xorg.conf


		;;

		*)

			# we dont force vesa
			printhl "..."

		;;

	esac

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
			#sed -i /'Section "Device"'/,/'EndSection'/s/'EndSection'/"\tOption      \"DynamicTwinView\"    \"false\"\nEndSection"/g /etc/X11/xorg.conf

			# remove stuff we dont need
			sed -i '/^.*VBERestore.*/d' /etc/X11/xorg.conf
			sed -i '/^.*XAANoOffscreenPixmaps.*/d' /etc/X11/xorg.conf
			sed -i '/^.*AIGLX.*/d' /etc/X11/xorg.conf
			sed -i '/^.*GLcore.*/d' /etc/X11/xorg.conf
			sed -i '/^.*"DRI"    "true".*/d' /etc/X11/xorg.conf

		elif [ -e "/tmp/catalyst" ] ; then
			printhl "Loading tainted kernel module: fglrx"
			modprobe fglrx &>/dev/null

                        aticonfig --initial --input=/etc/X11/xorg.conf
    
		else                   
			# we are using a free driver, so we add DRI stuff
			echo 'Section "DRI"' >> /etc/X11/xorg.conf
			echo '        Group  "video"' >> /etc/X11/xorg.conf
			echo '        Mode   0666' >> /etc/X11/xorg.conf
			echo 'EndSection' >> /etc/X11/xorg.conf
			echo ' ' >> /etc/X11/xorg.conf
		fi                     
		;;

		*)

			# we are using a free driver, so we add DRI stuff
			echo 'Section "DRI"' >> /etc/X11/xorg.conf
			echo '        Group  "video"' >> /etc/X11/xorg.conf
			echo '        Mode   0666' >> /etc/X11/xorg.conf
			echo 'EndSection' >> /etc/X11/xorg.conf
			echo ' ' >> /etc/X11/xorg.conf

		;;
	esac
