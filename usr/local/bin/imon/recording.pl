#!/usr/bin/perl

use strict;
use FindBin;                        # locate this script
use lib "$FindBin::Bin/.";     # use the RFLibs directory
use RFLibs::iMON;
use RFLibs::iMON::Utils;
use RFLibs::iMON::Text;
use Time::HiRes qw(usleep);

my $lcd_device = '/dev/lcd0';
my $imon_version = '15c2:0038';
my $fontpath = 'RFLibs/fonts';

# to conserve memory, call the functions that create threads after we declare shared variables, 
# but before we declare non-shared variables.
setupImon($lcd_device, $imon_version);
setupImonUtils();
setupImonText($fontpath);

clearLCD();
initScreens();
processLCDUpdates();
cleanupImonText();
cleanupImonUtils();
clearLCD();
setLCDMode('off');
cleanupImon();
exit;

#create the various screens that will be needed
sub initScreens
{
   createTextArea('myTextArea', 'big', 'none', 'none', 'center');
   createScreen('myText', 'none', 'none', 'myTextArea');   
   setAreaText('myTextArea', sprintf("%s", 'Aufnahme'));
}

#initialze the lcd to all clear
sub clearLCD
{
	setLCDMode('normal');
	setContrast(0.15);
	setFunction();
	setAudio();
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

#main loop for the application.
sub processLCDUpdates
{
   showScreen('');
   usleep(500000);
   showScreen('myText');
   usleep(700000);
   showScreen('');
   usleep(500000);
   showScreen('myText');
   usleep(700000);
   showScreen('');
   usleep(500000);
   showScreen('myText');
   usleep(700000);
   showScreen('');   
   usleep(1000000);   
};

