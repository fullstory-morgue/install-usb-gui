/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * callbacks.c
 * Copyright (C) Horst Tritremmel 2007 <hjt@sidux.com>
 * 
 * callbacks.c is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 * 
 * callbacks.c is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <gtk/gtk.h>

#include "callbacks.h"
#include <glade/glade.h>

#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <libintl.h>


GladeXML *gxml, *gxml_install_warning;
const gchar *file_iso, *entry_usb_result, *combobox_device_result, *combobox_lang_result;
char glade_file_install_warn[1024];
gboolean checkbutton_persist_result, checkbutton_toram_result;


void
dialog_msg_cb (	GtkWidget *window,
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
create_install_warning (void)
{

	GtkWidget *install_warning;
	
	gxml_install_warning = glade_xml_new (glade_file_install_warn, NULL, NULL);
		
	// This is important
	glade_xml_signal_autoconnect (gxml_install_warning);
	install_warning = glade_xml_get_widget (gxml_install_warning, "install_warning");
	
	return install_warning;
}


void
on_button_install_clicked (GtkButton *button, 
						   gpointer user_data)
{

	GtkWidget *window = glade_xml_get_widget (gxml, "window");
		
	GtkWidget *entry_usb             = glade_xml_get_widget (gxml, "entry_usb");
	GtkWidget *combobox_device       = glade_xml_get_widget (gxml, "combobox_device");
	GtkWidget *combobox_lang         = glade_xml_get_widget (gxml, "combobox_lang");
	GtkWidget *filechooserbutton_iso = glade_xml_get_widget (gxml, "filechooserbutton_iso");
	GtkWidget *checkbutton_persist   = glade_xml_get_widget (gxml, "checkbutton_persist");
	GtkWidget *checkbutton_toram     = glade_xml_get_widget (gxml, "checkbutton_toram");
	
	entry_usb_result           = gtk_entry_get_text(GTK_ENTRY( entry_usb ) );
	combobox_device_result     = gtk_combo_box_get_active_text(GTK_COMBO_BOX ( combobox_device ) );
	combobox_lang_result       = gtk_combo_box_get_active_text(GTK_COMBO_BOX ( combobox_lang ) );
	checkbutton_persist_result = gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON( checkbutton_persist ) );
	checkbutton_toram_result   = gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON( checkbutton_toram ) );

	
	if( strncmp( getenv("FLL_DISTRO_MODE"), "live", 4 ) != 0 ) {
		// installed mode
		file_iso = gtk_file_chooser_get_filename( GTK_FILE_CHOOSER (filechooserbutton_iso) );
		if (! (file_iso != NULL && strlen(file_iso) > 4) ) {

			dialog_msg_cb ( window, gettext("No ISO selected!") );
			return;
		}
	}
	
	
	// start the install warning
	GtkWidget *install_warning = create_install_warning ();
	gtk_widget_hide (window);
	gtk_widget_show (install_warning);
}


void
on_button_install_cancel_clicked(	GtkButton *button, 
					gpointer user_data)
{
	GtkWidget *window = glade_xml_get_widget (gxml, "window");
	GtkWidget *install_warning = glade_xml_get_widget (gxml_install_warning, "install_warning");
	
	gtk_widget_show (window);
	gtk_widget_destroy (install_warning);
}


void
on_button_install_accepted_clicked(GtkButton *button, 
						   gpointer user_data)
{

	g_print("%s\n", entry_usb_result);
	g_print("%s\n", combobox_device_result);
	g_print("%s\n", combobox_lang_result);
	if ( checkbutton_persist_result == TRUE ) {
		g_print("persist=1\n");
	}
	else {
		g_print("persist=0\n");
	}

	if ( checkbutton_toram_result == TRUE ) {
		g_print("toram=1\n");
	}
	else {
		g_print("toram=0\n");
	}

	if( strncmp( getenv("FLL_DISTRO_MODE"), "live", 4 ) != 0 ) {
		// installed mode
		g_print("%s\n", file_iso);
	}

	gtk_main_quit ();
}
