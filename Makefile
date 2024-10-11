# DroidCam & DroidCamX (C) 2010-2021
# https://github.com/dev47apps
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# Use at your own risk. See README file for more details.

#
# Variables with ?= can be changed during invocation
# Example:
#  APPINDICATOR=ayatana-appindicator3-0.1 make droidcam

UNAME_S = $(shell uname -s)

ifeq ($(UNAME_S),FreeBSD)
	CC       ?= gcc
else
	CC       ?= $(shell pkg info | grep -o '^gcc[0-9]*' | head -n 1)
endif

CLI          ?= 0
APPINDICATOR ?= appindicator3-0.1
USBMUXD      ?= libusbmuxd # Leave empty for disable
CFLAGS       ?= -Wall -O2

SRC     = src/connection.c src/settings.c src/decoder*.c src/av.c src/usb.c src/queue.c
LDFLAGS = -lspeex -lasound -lpthread -lm

# libav / libswscale
CFLAGS  += `pkg-config --cflags libswscale libavutil`
LDFLAGS += `pkg-config --libs libswscale libavutil`
LDFLAGS += -L/opt/ffmpeg4/lib -lswscale -lavutil

# libturbojpeg
CFLAGS  += `pkg-config --cflags libturbojpeg`
CFLAGS  += -I/opt/libjpeg-turbo/include
LDFLAGS += `pkg-config --libs libturbojpeg`

# USBMUXD
ifeq ($(USBMUXD),)
	CFLAGS  += "-DNOUSBMUXD"
else
	CFLAGS  += `pkg-config --cflags $(USBMUXD)`
	CFLAGS  += -I/opt/libimobiledevice/include
	LDFLAGS += `pkg-config --libs $(USBMUXD)`
endif

ifeq ($(CLI),0)
	SRC     += src/droidcam.c src/resources.c
	# GTK
	CFLAGS  += `pkg-config --cflags gtk+-3.0`
	LDFLAGS += `pkg-config --lib gtk+-3.0` `pkg-config --libs x11`
	# App Indicator
	CFLAGS  += `pkg-config --cflags $(APPINDICATOR)`
	LDFLAGS += `pkg-config --libs $(APPINDICATOR)`
ifneq ($(findstring ayatana,$(APPINDICATOR)),)
	CFLAGS  += -DUSE_AYATANA_APPINDICATOR
endif
else
	SRC     += src/droidcam-cli.c
endif

all:
	make build $(MAKECMDGOALS) CLI=0
	make build $(MAKECMDGOALS) CLI=1

build: $(SRC)
	$(CC) $(CFLAGS) $^ -o $@ $(SRC) $(LDFLAGS) $(CFLAGS)

package: LDFLAGS += "/opt/libjpeg-turbo/lib64/libturbojpeg.a /opt/libimobiledevice/lib/libusbmuxd.a /opt/libimobiledevice/lib/libplist-2.0.a"
package: all
	zip "droidcam_$(RELEASE).zip" \
		LICENSE README* icon2.png  \
		droidcam* install* uninstall* \
		v4l2loopback/*

#src/resources.c: .gresource.xml icon2.png
#	glib-compile-resources .gresource.xml --generate-source --target=src/resources.c

clean:
	rm -f droidcam
	rm -f droidcam-cli
	make -C v4l2loopback clean
