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


SELF=".bash"


#################################################################
#			root?					#
#################################################################
if (($UID)); then
	DISPLAY= exec su-me "$0 --uid $UID" "$@"
fi


# we need gettext (is loaded in ssft.sh or cloned...)
if [ -f /usr/bin/gettext.sh ]; then
	. /usr/bin/gettext.sh || exit 1
else
	exit 1
fi

TEXTDOMAIN=install-usb-gui
export TEXTDOMAIN
TEXTDOMAINDIR=/usr/share/locale
export TEXTDOMAINDIR


# exec code -----------------------------------------------------
INSTALL_USB_GUI="$(which install-usb-gui)"			|| INSTALL_USB_GUI="/usr/bin/install-usb-gui"
INSTALL_FROMISO_IN_USB="$(which install_fromiso_in_USB)"	|| INSTALL_FROMISO_IN_USB="/usr/sbin/install_fromiso_in_USB"
SSFTSH="$(which ssft.sh)"					|| SSFTSH="/usr/bin/ssft.sh"
# initialize ssft
. "$SSFTSH"
[ -n "$SSFT_FRONTEND" ] ||  SSFT_FRONTEND="$(ssft_choose_frontend)"


# install_fromiso_in_USB check ----------------------------------
if [ ! -x "$INSTALL_FROMISO_IN_USB" ]; then
	printf "\n$INSTALL_FROMISO_IN_USB not found\n\n"
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
export CHEATCODE_TORAM=$(grep -c toram /proc/cmdline)

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


# language cheatcode, special handling of en_* lang cheatcodes
case ${LANG%.*} in
	en_*)
		LANG_DEFAULT="lang=$(echo ${LANG%.*} | cut -d_ -f2 | tr [[:upper:]] [[:lower:]])"
		;;
	*_*)
		LANG_DEFAULT="lang=$(echo ${LANG%.*} | cut -d_ -f1)"
		;;
esac
export LANG_DEFAULT=${LANG_DEFAULT}

# persist cheatcode removed from LANG_DEFAULT variable, it can be written better
# eg, in a variable name that "describes" its purpose

# start the gui
result=$( exec $INSTALL_USB_GUI )


# set the variables who came back from gui
count=0
IFS=$'\n'
for i in $result; do

	case "$count" in
	0)
		combobox_device=$i;;
	1)
		[ "$i" = "_" ] && cheat="" || cheat="-- $i";;

	2)
		filechooserbutton_iso=$i;;
	*)
		printf "Cancel or Error with Variable\n";
		exit 1;;
	esac

	((count++))
done
IFS=$' \t\n'

# Cancel Button = exit
[ -z "$combobox_device" ] && exit


# ==============================================================
# 		start the installation
# ==============================================================
if [ "$FLL_DISTRO_MODE" = live ]; then
	RUN_SH="$INSTALL_FROMISO_IN_USB -D $combobox_device ${cheat}"
else
	RUN_SH="$INSTALL_FROMISO_IN_USB -D $combobox_device -I $filechooserbutton_iso ${cheat}"
fi

printf "$RUN_SH\n"
x-terminal-emulator -e $RUN_SH

# lookup the return code from install-fromiso-in-usb
test -e /tmp/.install_fromiso_in_USB && rc=$(</tmp/.install_fromiso_in_USB) || rc=0

case "${rc%-*}" in
        0)
		MSG=$(gettext "Install successful")
		;;
	255)
		MSG="internal error...\n\n**STOP**"
		;;
        *)
		MSG="${rc#*-}\n\n**STOP**"
		;;
esac

ssft_display_message $(gettext "USB-Installation") "${MSG}\n\n"

# unset the variables -------------------------------------------
count=0
while [  $count -lt $z ]; do
	unset USBDEVICE$count
	((count++))
done

