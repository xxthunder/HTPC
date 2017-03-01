#!/bin/bash

##################################################
#
# Start the VDR client.
#
# karsten.guenther@kamg.de
#
##################################################

### VDPAU support
vdr-sxfe --fullscreen --height=1080 --width=1920 --audio alsa:plughw:0,7 --video=vdpau --post tvtime:method=use_vo_driver xvdr://localhost

### Works, but poor deinterlacing
#vdr-sxfe --fullscreen --lirc --audio=alsa:plug:iec958 --post tvtime:method=Linear,cheap_mode=1,pulldown=0,use_progressive_frame_flag=1 xvdr://localhost
