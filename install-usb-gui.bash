#!/bin/bash
# install-usb-gui.bash
# Copyright (C) Horst Tritremmel 2007 <hjt@users.berlios.de>
#           (C) Joaquim Boura    2009 <x-un-i@berlios.de>
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
INSTALL_USB_GUI="$(which install-usb-gui)" || INSTALL_USB_GUI="/usr/bin/install-usb-gui"
INSTALL_ISO2USB="$(which fll-iso2usb)"     || INSTALL_ISO2USB="/usr/sbin/fll-iso2usb"
SSFTSH="$(which ssft.sh)"                  || SSFTSH="/usr/bin/ssft.sh"
# initialize ssft
. "$SSFTSH"
[ -n "$SSFT_FRONTEND" ] ||  SSFT_FRONTEND="$(ssft_choose_frontend)"


# fll-iso2usb check ----------------------------------
if [ ! -x "$INSTALL_ISO2USB" ]; then
	printf "\n$INSTALL_ISO2USB not found\n\n"
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


# language cheatcode
case ${LANG%.*} in
	*_*)
		LANG_DEFAULT="lang=$(echo ${LANG%.*})"
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
if [ -f "${filechooserbutton_iso}" ] || [ -b "${filechooserbutton_iso}" ]; then
	RUN_SH="$INSTALL_ISO2USB -D $combobox_device -I '${filechooserbutton_iso}' ${cheat}"
elif [ "$FLL_DISTRO_MODE" = live ]; then
	RUN_SH="$INSTALL_ISO2USB -D $combobox_device ${cheat}"
else
	printf "Error with Mode of operation\n";
	exit 1
fi

# create tempfile
tmpfil="$(mktemp -p /tmp/ .XXXXXXXXXX)"

# prepare shell script
cat >>${tmpfil} <<EOF
#!/bin/bash

echo enter the root password
su -c "$RUN_SH"

EOF

# make it executable
chmod 755 ${tmpfil}

# remove file with the return code from previous runs
test -e /tmp/.fll-iso2usb && rm -f /tmp/.fll-iso2usb

# launch terminal and the backend
x-terminal-emulator -e ${tmpfil}

# wait a bit till the backend starts
sleep 3
# loop until fll-iso2usb is done
while true; do  cnt=$(ps ax | grep -v grep |grep -e iso2usb  |wc -l); if [ $cnt -eq  0 ]; then  break; else sleep 3; sync; fi; done

#remove temp file
test -e ${tmpfil} && rm -f ${tmpfil}

# lookup the return code from the backend
# when user entered wrong root password the file with the return code does not exist
test -e /tmp/.fll-iso2usb && rc=$(</tmp/.fll-iso2usb) || rc="user abort"

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

