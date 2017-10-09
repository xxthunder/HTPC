#!/bin/bash

### Start the VDR client with VDPAU support ###

vdr-sxfe --fullscreen --height=1080 --width=1920 --audio alsa:plughw:0,7 --video=vdpau --post tvtime:method=use_vo_driver xvdr://localhost
