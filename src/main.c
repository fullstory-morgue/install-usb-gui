/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * main.c
 * Copyright (C) Horst Tritremmel 2007 <hjt@sidux.com>
 * 
 * main.c is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 * 
 * main.c is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <config.h>

#include <gtk/gtk.h>
#include <glade/glade.h>


/*
 * Standard gettext macros.
 */
#ifdef ENABLE_NLS
#  include <libintl.h>
#  undef _
#  define _(String) dgettext (PACKAGE, String)
#  ifdef gettext_noop
#    define N_(String) gettext_noop (String)
#  else
#    define N_(String) (String)
#  endif
#else
#  define textdomain(String) (String)
#  define gettext(String) (String)
#  define dgettext(Domain,Message) (Message)
#  define dcgettext(Domain,Message,Type) (Message)
#  define bindtextdomain(Domain,Directory) (Domain)
#  define _(String) (String)
#  define N_(String) (String)
#endif


#include "callbacks.h"

#define BUF_LEN    1024


#define GLADE_FILE                 PACKAGE_DATA_DIR"/install-usb-gui/src/install-usb-gui.glade"
#define GLADE_FILE_NO_USB          PACKAGE_DATA_DIR"/install-usb-gui/src/no_usb.glade"
#define GLADE_FILE_INSTALL_WARNING PACKAGE_DATA_DIR"/install-usb-gui/src/install_warning.glade"


extern GladeXML *gxml;
extern char glade_file_install_warn[1024];


void
dialog_msg (GtkWidget *window,
			char *message)
{
		GtkWidget *dialog = gtk_message_dialog_new ( GTK_WINDOW( window ),
						GTK_DIALOG_DESTROY_WITH_PARENT,
						GTK_MESSAGE_ERROR,
						GTK_BUTTONS_CLOSE,
						"%s\n", message );
		gtk_dialog_run (GTK_DIALOG (dialog));
		gtk_widget_destroy (dialog);
}


GtkWidget*
create_window (void)
{
	GtkWidget *window;
	GtkFileFilter *filter;
	//GtkWidget *combobox2;
	int z = 0;
	char USBDEVICE_VAR[BUF_LEN];
	//char LOCALE_VAR[BUF_LEN];
	

	if( strncmp( getenv("USBDEVICE0"), "no_usb_found", 12 ) != 0 ) {  // usb device found
		gxml = glade_xml_new (GLADE_FILE, NULL, NULL);
		
		// This is important
		glade_xml_signal_autoconnect (gxml);
		window = glade_xml_get_widget (gxml, "window");
	
		// filter for filechooser, only .iso files
		GtkWidget *filechooserbutton_iso = glade_xml_get_widget (gxml, "filechooserbutton_iso");
	
		filter = gtk_file_filter_new ();
		gtk_file_filter_add_pattern (filter, "*.iso");
		gtk_file_filter_add_pattern (filter, "*.ISO");
		gtk_file_filter_add_pattern (filter, "/dev/cdrom*");
		gtk_file_filter_add_pattern (filter, "/dev/dvd*");

		gtk_file_chooser_add_filter (GTK_FILE_CHOOSER (filechooserbutton_iso), filter);

		// set current dir for file chooser
		if (!getenv("HOME")) {
			dialog_msg( window, gettext("getenv HOME isn't defined") );
		}
		else {
			// set the current folder now
			gtk_file_chooser_set_current_folder (GTK_FILE_CHOOSER (filechooserbutton_iso), getenv("HOME"));
		}

	
		// hide the iso file chooser in live mode and without cheatcode toram
		if (!getenv("FLL_DISTRO_MODE")) {
			dialog_msg( window, gettext("getenv FLL_DISTRO_MODE isn't defined\nPlease start with install-usb-gui.bash" ));	
		}
		else {

			if( strncmp( getenv("FLL_DISTRO_MODE"), "live", 4 ) == 0 && \
			    strncmp( getenv("CHEATCODE_TORAM"), "0", 1 ) == 0 ) {
				// hide now
				GtkWidget *label_iso = glade_xml_get_widget (gxml, "label_iso");
				gtk_widget_destroy (label_iso);
				gtk_widget_destroy (filechooserbutton_iso);
			}		
		}
	
		// combobox_device entrys
		snprintf (USBDEVICE_VAR, BUF_LEN, "USBDEVICE%d", z);
	
		while ( getenv( USBDEVICE_VAR ) ) {
		
			GtkWidget *combobox = glade_xml_get_widget ( gxml, "combobox_device");
			gtk_combo_box_append_text( GTK_COMBO_BOX (combobox), getenv( USBDEVICE_VAR ) );
			gtk_combo_box_set_active(GTK_COMBO_BOX(combobox),0);

			z++;
			snprintf (USBDEVICE_VAR, BUF_LEN, "USBDEVICE%d", z);
		}

		// default cheatcodes
		GtkWidget *entry_cheat = glade_xml_get_widget (gxml, "entry_cheat");
		gtk_entry_set_text( GTK_ENTRY ( entry_cheat  ), getenv( "LANG_DEFAULT" ) );

	}
	else {		//no usb device found
	
		gxml = glade_xml_new (GLADE_FILE_NO_USB, NULL, NULL);
		
		// This is important
		glade_xml_signal_autoconnect (gxml);
		window = glade_xml_get_widget (gxml, "window");
	}
	
	return window;
}


int
main (int argc, char *argv[])
{
 	GtkWidget *window;


#ifdef ENABLE_NLS
	bindtextdomain (GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR);
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
	textdomain (GETTEXT_PACKAGE);
#endif

	gtk_set_locale ();
	gtk_init (&argc, &argv);

	if (!getenv("USBDEVICE0")) {
		printf(gettext("\n No USBDEVICE0 Variable found!\n Please start with install-usb-gui.bash\n\n"));	
		return 1;
	}
	
	strncpy ( glade_file_install_warn, GLADE_FILE_INSTALL_WARNING, BUF_LEN );
		
	window = create_window ();
	gtk_widget_show (window);

	gtk_main ();
	
	return 0;
}
