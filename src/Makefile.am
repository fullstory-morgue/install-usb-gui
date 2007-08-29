## Process this file with automake to produce Makefile.in

## Created by Anjuta

gladedir = $(datadir)/install-usb-gui/glade
glade_DATA = install-usb-gui.glade \
	no_usb.glade\
	install_warning.glade

INCLUDES = \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	$(INSTALL_USB_GUI_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

bin_PROGRAMS = install-usb-gui

install_usb_gui_SOURCES = \
	callbacks.c \
	callbacks.h \
	main.c

install_usb_gui_LDFLAGS = \
	-export-dynamic

install_usb_gui_LDADD = $(INSTALL_USB_GUI_LIBS)

EXTRA_DIST = $(glade_DATA)
