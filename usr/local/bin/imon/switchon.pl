#!/usr/bin/perl

################################################################################
#
#	Created by Ronald Frazier
#	http://www.ronfrazier.net
#
#	Feel free to do anything you want with this library, as long as you
#	do not remove the above attribution.
#
################################################################################

use strict;
use RFLibs::iMON;
use RFLibs::iMON::Utils;
use RFLibs::iMON::Text;

my $lcd_device = '/dev/lcd0';
my $imon_version = '15c2:0038';

# to conserve memory, call the functions that create threads after we declare shared variables, 
# but before we declare non-shared variables.
setupImon($lcd_device, $imon_version);
setupImonUtils();
setupImonText();

my @screen_group_order;
my %screen_group;
my %first_screen;
my %next_screen;

clearLCD();
setAudio('spdif');
setCodec('ac3');
cleanupImon();
exit;

#initialze the lcd to all clear
sub clearLCD
{
	setLCDMode('normal');
	setContrast(0.15);
	setFunction();
	setAudio('spdif');
#	setSource();
	setCodec();
	setMiscIcon('time', 0);
	setMiscIcon('alarm', 0);
	setMiscIcon('record', 0);
	setMiscIcon('volume', 0);
	setPlaybackOrder();
	setTrayStatus();
	setDiscMode('off');
	setBars([0,1,2,3], 0);
	setBitmap();
};
