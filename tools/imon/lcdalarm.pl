#!/usr/bin/perl

#######################################################
#
#  Perl script to program the wakeup timer
#  of the Soundgraph iMON LCD used in the
#  Antec Fusion Remote HTPC case.
#
#  karsten.guenther@kamg.de
#
#  Inspired by RFLibs created by Ronald Frazier
#	http://www.ronfrazier.net
#
#  Revision:     $Rev$  
#  Author:       $Author$  
#  Date:         $Date$
#  URL:          $HeadURL$  
#
#######################################################

use Date::Calc;
use Time::HiRes qw(usleep);
use Time::Local;
use FileHandle;
use Getopt::Std;

my $lcd_device    = '/dev/lcd0';
my $imon_version  = '15c2:0038';
my $display_code  = '88';
my $alarm_code    = '8a';
my $debug         = 0;
	
getopts('dm:') or die "Invalid options!\n";

if (!$opt_m) 
{            
    die "Usage: lcdalarm.pl [-d] -m <minutes till next timer>\n";
}

if ($opt_d) 
{            
    print "Debug output only, LCD alarm will not be programmed!\n";
    $debug = 1;
}

# Wakeup HTPC in '$ARGV[0]' minutes
setLCDAlarm($opt_m);
exit;

sub setLCDAlarm
{
   my @commands;  

   # 0x20 -> timer function
   # 0x08 -> switch backlight off
   # 0x28 -> both, exactly what I wanted ;-)  
   my $firstbyte = 0x28;

   my $delay_minutes = shift @_;

   my @current_time = localtime(time());
   my @wakeup_time  = localtime(time() + $delay_minutes*60);

   if ($debug)
   {
      print "Current date  : ".localtime(timelocal(@current_time))."\n";  
      print "Wakeup date   : ".localtime(timelocal(@wakeup_time))." \n";  
   }

   my ($ct_minute,
       $ct_hour,
       $ct_day,
       $ct_month,
       $ct_year) = (@current_time)[1,2,3,4,5];

   # get the exact alarm date and time
   my ($wt_minute,
       $wt_hour,
       $wt_day,
       $wt_month,
       $wt_year) = (@wakeup_time)[1,2,3,4,5];

   # correct month and year for delta days calculation
   $ct_month += 1;
   $ct_year  += 1900;
   $wt_month += 1;
   $wt_year  += 1900;

   if ($debug)
   {
      print "Today         : ".$ct_day.".".($ct_month).".".($ct_year)."\n";
      print "Wakeup day    : ".$wt_day.".".($wt_month).".".($wt_year)."\n";
   }

   # get the day delta between now and the wake-up time 
   $Dd = Date::Calc::Delta_Days($ct_year,$ct_month,$ct_day,
                                $wt_year,$wt_month,$wt_day);
  
   if ($debug)
   {
      print "Delta days    : ".$Dd."\n";
   }
		
   push @commands, sprintf("%02x 00 00 00 %02x %02x %02x %s", $firstbyte, $ct_hour, $ct_minute, $ct_second, $display_code);
   push @commands, sprintf("00 %02x %02x %02x 00 00 00 %s",   $Dd,        $wt_hour, $wt_minute, $alarm_code              );
	
   if ($debug)
   {
      print "Command 0     : ".@commands[0]."\n";
      print "Command 1     : ".@commands[1]."\n";
   }
   else
   {
      WriteToLCD(@commands);
   }
};

sub WriteToLCD
{
   my $LCDHandle = new FileHandle(">$lcd_device") or die "Can't open $lcd_device";
   $LCDHandle->autoflush(1);

   my (@hex_commands) = @_;

   foreach my $hex (@hex_commands)
   {
      $hex =~ s/ //g;
      my $data = pack("H*", $hex);
      syswrite($LCDHandle, $data);
      usleep(2000);
   };

   $LCDHandle->close() or die "Can't close LCD";
};

