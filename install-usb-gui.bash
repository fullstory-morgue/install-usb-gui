#!/bin/bash
# install-usb-gui.bash
# Copyright (C) Horst Tritremmel 2007 <hjt@sidux.com>
# 
# install-usb-gui.bash is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# install-usb-gui.bash is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.


PERSIST_OPTION="-p"


#################################################################
#		root?						#
#################################################################
if (($UID)); then
	DISPLAY= exec su-me "$0 --uid $UID" "$@"
fi


# exec code -----------------------------------------------------
INSTALL_USB_GUI="$(which install-usb-gui)"			|| INSTALL_USB_GUI="/usr/bin/install-usb-gui"
INSTALL_FROMISO_IN_USB="$(which install_fromiso_in_USB)"	|| INSTALL_FROMISO_IN_USB="/usr/bin/install_fromiso_in_USB"


# install_fromiso_in_USB check ----------------------------------
if [ ! -x "$INSTALL_FROMISO_IN_USB" ]; then
	printf "\n$INSTALL_FROMISO_IN_USB not found\ninstall sidux-scripts package\n\n"
	exit 1
fi


# distro source -------------------------------------------------
if [ -e "/etc/default/distro" ]; then
	. /etc/default/distro
else
	printf "\n/etc/default/distro not found\n\n"
	exit 1
fi

export FLL_DISTRO_MODE
export USBDEVICE0="no_usb_found"


# search the usb devices and set the result in variables (USBDEVICE${z}) for the gui
z=0
for d in /dev/disk/by-id/usb-*; do 
	case $d in *-part*[0-9]) 
		continue;; 
	esac

	[ -L "$d" ] && LINK=$(readlink -f $d)
	case $LINK in *[0-9])  # no usb burner
		continue;; 
	esac

	[ -n "$LINK" ] && export USBDEVICE${z}=$LINK && ((z++))
	printf "$LINK\n"
done


# start the gui
result=$( exec $INSTALL_USB_GUI )


# set the variables who came back from gui
count=0
for i in $result; do

	case "$count" in
	0)
		entry_usb=$i;;
	1)
		combobox_device=$i;;
	2)
		[ "$i" = "persist=1" ] && persist="$PERSIST_OPTION" || persist="";;
	3)
		filechooserbutton_iso=$i;;
	*)
		printf "Cancel or Error with Variable\n";
		exit 1;;
	esac

	((count++))
done

# Cancel Button = exit
[ -z "$entry_usb" ] && exit


# ==============================================================
# 		start the installation
# ==============================================================
if [ "$FLL_DISTRO_MODE" = live ]; then
	RUN_SH="$INSTALL_FROMISO_IN_USB -D $entry_usb $persist -L $entry_usb"
else
	RUN_SH="$INSTALL_FROMISO_IN_USB -D $entry_usb $persist -L $entry_usb -I $filechooserbutton_iso"
fi

x-terminal-emulator -e $RUN_SH


# unset the variables -------------------------------------------
count=0
while [  $count -lt $z ]; do
	unset USBDEVICE$count
	((count++))
done

