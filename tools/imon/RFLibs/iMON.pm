package RFLibs::iMON;
$RFLibs::iMON::VERSION = '1.00';

################################################################################
#
#	Created by Ronald Frazier
#	http://www.ronfrazier.net
#
#	Feel free to do anything you want with this, as long as you
#	include the above attribution.
#
################################################################################

use strict;
use threads;
use threads::shared;
use Thread::Queue;
use Time::HiRes qw(usleep);
use FileHandle;
use Date::Calc;

use RFLibs::Threads 1.00;



@RFLibs::iMON::ISA = qw(Exporter);
@RFLibs::iMON::EXPORT = qw(
			setupImon
			cleanupImon

			setLCDAlarm
			setLCDMode
			setContrast
			
			setFunction
			setAudio
			setDisplay
			setCodec
			setPlaybackOrder
			setDiscMode
			setTrayStatus
			setMiscIcon
			setBars
			setBarAnimation
			setBitmap
			setEQLevel
                      );


my $LCDMode : shared = '';
my @bars : shared = (0,0,0,0);
my $EQMode : shared = 0;
my %icons : shared;

my $display_code;
my $alarm_code;

$icons{function} = 0;
$icons{audio} = 0;
$icons{display} = 0;
$icons{codec} = 0;
$icons{order} = 0;
$icons{misc} = 0;
$icons{disc} = 0;
$icons{tray} = 0;


my $LCDHandle = 0;
my $commandQueue;
my $animationQueue;
my %misc_icon_offset = 
	('time'    => 0, 
	 'vol'     => 1,
	 'rec'     => 2,
	 'alarm'   => 3);

my %animationData;

sub setupImon
{
	my ($device, $version) = @_;
	
	($display_code, $alarm_code) = ($version eq '15c2:0038') ? ('88', '8a') : ('50', '51');
	
	$LCDHandle = new FileHandle(">$device") or die "Can't open $device";
	$LCDHandle->autoflush(1);
	$commandQueue = new Thread::Queue();
	$animationQueue = new Thread::Queue();
	thread_start('imon_display', \&threadbody_processCommands);
	thread_start('imon_animation', \&threadbody_animation);
};


sub cleanupImon
{
	$animationQueue->enqueue(undef);
	thread_stop('imon_animation');
	$commandQueue->enqueue(undef);
	thread_stop('imon_display');
	$LCDHandle->close() or die "Can't close LCD";
};

sub setLCDAlarm
{
   my @commands;  

   my $firstbyte = 0x28;
   my ($second, $minute, $hour, $day, $month, $year) = localtime();

   my ($Dd, $alarm_year, $alarm_month, $alarm_day, $alarm_hour, $alarm_min, @icons);
		
   my $delay_minutes = shift @_;
   ($alarm_min, $alarm_hour, $alarm_day, $alarm_month, $alarm_year) = (localtime(time() + $delay_minutes*60))[1,2,3,4,5];

   $Dd = Date::Calc::Delta_Days($year,$month,$day,
			        $alarm_year,$alarm_month,$alarm_day);

   print "Now     : ".$day.", ".$hour.":".$minute."\n";
   print "Start   : ".$alarm_day.", ".$alarm_hour.":".$alarm_min."\n";
   print "Deltaday: ".$Dd."\n";
		
   push @commands, sprintf("%02x 00 00 00 %02x %02x %02x %s", $firstbyte, $hour, $minute, $second, $display_code);
   push @commands, sprintf("00 %02x %02x %02x 00 00 00 %s", $Dd, $alarm_hour, $alarm_min, $alarm_code);
	
   sendCommands(@commands);
};


sub setLCDMode
{
	my $mode = shift @_;
	
	my @commands;
	if ($mode =~  /^(clock|alarm|timer)$/)
	{
		my $firstbyte = ($mode eq 'clock') ? 0x80 : 0x28;
		my ($second, $minute, $hour) = localtime();
		
		my ($alarm_hour, $alarm_min, @icons);
		
		if ($mode eq 'alarm')
		{
			$alarm_hour = shift @_;
			$alarm_min = shift @_;
		}
		elsif ($mode eq 'timer')
		{
			my $delay_minutes = shift @_;
			($alarm_min, $alarm_hour) = (localtime(time() + $delay_minutes*60))[1,2];
		};
		
		@icons = @_;

		foreach my $icon (@icons)
		{
			$firstbyte |= 0x01 if $icon eq 'music';
			$firstbyte |= 0x02 if $icon eq 'tv';
		};
		
		push @commands, sprintf("%02x 00 00 00 %02x %02x %02x %s", $firstbyte, $hour, $minute, $second, $display_code);
		push @commands, sprintf("00 00 %02x %02x 00 00 00 %s", $alarm_hour, $alarm_min, $alarm_code) if ($mode ne 'clock');
	}
	elsif ($mode eq 'off')
	{
		push @commands, "08 00 00 00 00 00 00 ".$display_code;
	}
	else
	{
		$mode = 'normal' unless $mode eq 'eq';
		if ($mode eq 'eq')
		{
			$EQMode = shift(@_) % 4;
		};

		push @commands, "40 00 00 00 00 00 00 ".$display_code;
	};
	
	$LCDMode = $mode;
	sendCommands(@commands);
};


sub setContrast
{
	my ($contrast) = @_;
	sendCommands(sprintf("%02x 00 00 00 00 00 00 03", $contrast*63));
};


sub setFunction
{
	my $bits = 0;
	foreach my $function (@_)
	{
		$bits |=
			($function eq 'music')   ? 0x40 :
			($function eq 'movie')   ? 0x20 :
			($function eq 'photo')   ? 0x10 :
			($function eq 'cd')      ? 0x08 :
			($function eq 'dvd')     ? 0x08 :
			($function eq 'tv')      ? 0x04 :
			($function eq 'webcast') ? 0x02 :
			($function eq 'news')    ? 0x01 :
			($function eq 'weather') ? 0x01 : 0;
	};
	
	handle('function', $bits);
};


sub setAudio
{
	my $bits = 0;
	foreach my $mode (@_)
	{
		$bits |=
			($mode eq 'stereo') ? 0x0140 :
			($mode eq '5.1') ? 0x01d5 :
			($mode eq '7.1') ? 0x01fd :
			($mode eq 'spdif') ? 0x0002 : 
			($mode eq 'fl') ? 0x0100 : 
			($mode eq 'fc') ? 0x0080 : 
			($mode eq 'fr') ? 0x0040 : 
			($mode eq 'sl') ? 0x0020 : 
			($mode eq 'lfe')? 0x0010 : 
			($mode eq 'sr') ? 0x0008 : 
			($mode eq 'rl') ? 0x0004 : 
			($mode eq 'rr') ? 0x0001 : 
			0;
	};
	handle('audio', $bits);
};


sub setDisplay
{
	my $bits = 0;
	foreach my $display (@_)
	{
		$bits |=
			($display eq 'src')  ? 0x20 :
			($display eq 'fit')  ? 0x10 :
			($display eq 'tv')   ? 0x08 :
			($display eq 'hdtv') ? 0x04 :
			($display eq 'src1') ? 0x02 :
			($display eq 'src2') ? 0x01 : 0;
	};
	
	handle('display', $bits);
};


sub setCodec
{
	my $bits = 0;
	foreach my $codec (@_)
	{
		$bits |=
			($codec eq 'mpg')       ? 0x800 :
			($codec eq 'divx')      ? 0x400 :
			($codec eq 'xvid')      ? 0x200 :
			($codec eq 'wmv')       ? 0x100 :

			($codec eq 'mpg_audio') ? 0x080 :
			($codec eq 'ac3')       ? 0x040 :
			($codec eq 'dts')       ? 0x020 :
			($codec eq 'wma')       ? 0x010 :

			($codec eq 'mp3')       ? 0x008 :
			($codec eq 'ogg')       ? 0x004 :
			($codec eq 'wma_music') ? 0x002 :
			($codec eq 'wav')       ? 0x001 : 0;
	};
	handle('codec', $bits);
};


sub setPlaybackOrder
{
	my $bits = 0;
	foreach my $order (@_)
	{
		$bits |=
			($order eq 'random')  ? 0x01 :
			($order eq 'shuffle') ? 0x01 :
			($order eq 'repeat')  ? 0x02 : 0;
	};
	handle('order', $bits);
}


sub setDiscMode
{
	my $status = shift @_;

	$animationQueue->enqueue('disc', 0);

	if ($status eq 'spin')
	{
		my ($spinType, $spinRate) = @_;
		$animationQueue->enqueue('disc', $spinRate, $spinType) if ($spinRate > 0);
		return;
	};

	my $bits = ($status eq 'on')  ? 0x00ff : 0;
	handle('disc', $bits);
}


sub setTrayStatus
{
	my $bits = 0;
	foreach my $tray (@_)
	{
		$bits |= ($tray =~ /^(open|eject)/)  ? 1 : 0;
	};
	handle('tray', $bits);
}


sub setMiscIcon
{
	my ($icon, $enabled) = @_;

	handle($1, $enabled != 0) if $icon =~ /^(time|vol|rec|alarm)(ume|ord)?$/;
};


sub setBars
{
	handle('bars', @_);
};

sub setBarAnimation
{
	my @params;

	while(scalar(@_) >= 2)
	{
		my $bars = shift @_;
		$bars = [$bars] unless ref($bars); #if the param is a single value, turn it into an arrayref
		my $style = shift @_;
		my $rate = shift @_;
		
		foreach my $bar (@$bars)
		{
			next if (($bar < 0) || ($bar > 3));
			push(@params, "bar$bar", $rate);
			push(@params, $style) if $rate > 0
		};
	};
	$animationQueue->enqueue(@params);
};

sub setBitmap
{
	handle('bitmap', @_);
};


sub handle
{
	my $action = lc(shift @_);
	if ($action =~ /^(disc|audio|function|display|codec|order|tray)$/)
	{
		lock(%icons);
		
		$icons{$action} = shift @_;
		updateIcons();
	}
	elsif ($action =~ /^(time|vol|rec|alarm)$/)
	{
		lock(%icons);
		
		my $offset = $misc_icon_offset{$action};
		my $misc = $icons{'misc'};
		$misc = $misc & ~(1 << $offset);
		$icons{'misc'} = $misc | ((shift @_) & 1) << $offset; 
		updateIcons();
	}
	elsif ($action eq 'bars')
	{
		while(scalar(@_) >= 2)
		{
			my $bar_nums = shift @_;
			my $bits = shift @_;
			foreach my $num (@$bar_nums)
			{
				$bars[$num] = $bits;
			};
		};
		my $noupdate = 0;
		if (scalar(@_)) {$noupdate = shift @_;};
		updateBars() unless $noupdate;
	}
	elsif ($action eq 'bitmap')
	{
		my ($bitmap) = @_;
		updateBitmap($bitmap);
	};
};


sub updateIcons()
{
	return unless ($LCDMode =~ /^(normal|eq)$/);

	my $command = 
		sprintf("%04x", ($icons{function} << 9)|$icons{audio}).
		sprintf("%02x", (($icons{display} << 2) | ($icons{codec} >> 10))).
		sprintf("%04x", (($icons{codec}&0x3ff) << 6) | ($icons{order} << 4) | $icons{misc}).
		sprintf("%02x", $icons{disc}).
		sprintf("%02x", ($icons{tray} << 7)).
		"01";

	sendCommands($command);
};


sub updateBars
{
	return unless ($LCDMode =~ /^(normal|eq)$/);

	my @commands;
	push @commands, sprintf("%08x%06x", $bars[0], ($bars[1]>>8)&0x00ffffff)."10";
	push @commands, sprintf("%02x%08x%04x", ($bars[1]&0x00ff), $bars[2], ($bars[3]>>16)&0x0000ffff)."11";
	push @commands, sprintf("%04x%010x", ($bars[3]&0x0000ffff), 0)."12";
	sendCommands(@commands);
};


sub updateBitmap
{
	my ($bitmap) = @_;

	$bitmap .= '0' x (14*(0x3b-0x20+1));

	return unless $LCDMode eq 'normal';
	
	my @commands;
	my $cmd;
	foreach my $cmdcode (0x20..0x3b)
	{
		my $data = substr($bitmap, 0, 14);
		$bitmap = substr($bitmap, 14);
		$cmd = $data.sprintf("%02x",$cmdcode);
		push @commands, $cmd;
	};
	#add the last line a second time...it forces the rendering of the display
	push @commands, $cmd;
	sendCommands(@commands);
};


sub sendCommands
{
	my (@hex_commands) = @_;

	my @commands;
	foreach my $hex (@hex_commands)
	{
		$hex =~ s/ //g;
		my $data = pack("H*", $hex);
		push @commands, $data;
	};
	while($commandQueue->pending() > 100)
	{
		threads->yield();
	};
	
	$commandQueue->enqueue(@commands);
};


sub setEQLevel
{
	return unless $LCDMode eq 'eq';
	
	my @left = @{shift @_};
	my @right;

	my $mode = sprintf("%02x", $EQMode);
	my $max = 15;
	

	if($mode =~ /^0[23]$/)
	{
		$max = 7;
		@right = @{shift @_} if scalar(@_);
	};



	my @bars;
	foreach (1..16)
	{
		my $r = int($max*shift(@right));
		my $l = int($max*shift(@left));
		push @bars, sprintf("%x%x ", $r, $l);
	};

	my @commands;
	push @commands, $mode.join('', splice(@bars,0,6)).'40';
	push @commands, join('', splice(@bars,0,7)).'41';
	push @commands, join('', @bars).'0000000042';

	sendCommands(@commands);
};

sub makeProgressBar
{
	my $progress = shift @_;
	$progress = $1/100 if $progress =~ /^(-?\d+)%/;

	my $count = int(abs($progress)*32);
	my $bits = (2**$count) - 1;
	$bits <<= (32-$count) if ($progress > 0);

	return $bits;
};

sub makeScrollBar
{
	my $position = shift @_;
	$position = $1/100 if $position =~ /^(\d+)%/;

	my $shift = int($position*28);
	my $bits = 0xf0000000 >> $shift;

	return $bits;
};



############################### VARIOUS THREAD FUNCTIONS ###############################


sub threadbody_processCommands
{
	while(my $command = $commandQueue->dequeue())
	{
		syswrite($LCDHandle, $command);
		usleep(2000);
	};
};



sub threadbody_animation
{
	MAINLOOP:
	while (1)
	{
		my $now = Time::HiRes::time();

		#process until the queue is empty...also, if there are no animations, then enter the loop so we can wait until something is pending
		PROCESSQUEUE:
		while($animationQueue->pending() || !scalar(keys(%animationData)))
		{
			#get the name of next animation to update...if it's undef, that means to terminate the thread
			my $name = $animationQueue->dequeue();
			last MAINLOOP unless defined $name;

		
			#find out the animation speed (fps). If zero, that means to stop the animation
			my $fps = $animationQueue->dequeue();
			if ($fps == 0)
			{
				delete $animationData{$name};
			}
			else #otherwise update (or create) the animation record
			{
				my $cancel_animation = 0;

				#handle the common stuff
				if (!exists($animationData{$name}))
				{
					$animationData{$name} = {};
				};
				my $data = $animationData{$name};
				$data->{interval} = 1/$fps;
				$data->{nextupdate} = $now;

				#then do stuff specific to each type of animation
				if ($name eq 'disc')
				{
					my $style = $animationQueue->dequeue();
					threadhelper_initDisc($data, $style) or $cancel_animation = 1;
				}
				elsif ($name =~ /^bar([0-3])$/)
				{
					my $bar = $1;
					my $style = $animationQueue->dequeue();
					threadhelper_initBar($data, $bar, $style) or $cancel_animation = 1;
				}
				else
				{
					print "Unhandled animation update for $name\n";
				};

				#cancel the animation if necessary
				delete $animationData{$name} if $cancel_animation;
			};
		};
		
		#now we can proces animations until something else shows up in the queue	
		DOANIMATIONS:
		while(!$animationQueue->pending())
		{
			#if there's no animations left, then we go back to waiting in the queue
			my @names = keys %animationData;
			last DOANIMATIONS unless scalar(@names);
			
			$now = Time::HiRes::time();
			
			#check each animation to see if it needs to be updated, and find out how long we can sleep
			my $sleeptime = 999999;
			my $updatebars = 0;
			foreach my $name (@names)
			{
				my $data = $animationData{$name};
				my $cancel_animation = 0;
				if ($now >= $data->{nextupdate})
				{
					#do the update here
					if ($name eq 'disc')
					{
						threadhelper_animateDisc($data) or $cancel_animation = 1;
					}
					elsif ($name =~ /^bar\d$/)
					{
						threadhelper_animateBar($data) or $cancel_animation = 1;
						$updatebars = 1;
					};
					
					$data->{nextupdate} = $now + $data->{interval};
				};

				#cancel the animation if necessary
				delete $animationData{$name} if $cancel_animation;

				#find the minimum time until something needs to be updated
				my $wait = $data->{nextupdate} - $now;
				$sleeptime = $wait if $wait < $sleeptime;
			};
			handle('bars') if $updatebars;


			#sleep off the time we need to wait until the next update, but do it in 1/10s of a second so we can 
			#periodically check for queue for new messages
			while($sleeptime > 0)
			{
				last DOANIMATIONS if $animationQueue->pending();
			
				my $wait = ($sleeptime > 0.1) ? 0.1 : $sleeptime;
				$sleeptime -= Time::HiRes::sleep($wait);
			};
		};
	};

};

sub threadhelper_initDisc
{
	my ($data, $style) = @_;

	$data->{bits} = 
		($style == 1) ? 0x01 :
		($style == 2) ? 0x11 :
		($style == 4) ? 0x55 :
		($style == 6) ? 0x77 :
		($style == 7) ? 0xfe :
		($style == -1) ? 0xfc :
		($style == -2) ? 0x33 : 0x00;

	return 0 if ($data->{bits} == 0x00);
	return 1;
};

sub threadhelper_animateDisc
{
	my ($data) = @_;
	
	handle('disc', $data->{bits});
	$data->{bits} = (($data->{bits} << 1) | (($data->{bits} >> 7) & 1)) & 0x00ff; #simulate the 8-bit ROL instruction
	
	return 1;
};


sub threadhelper_initBar
{
	my ($data, $bar, $style) = @_;

	$data->{bar} = $bar;
	$style =~ /^(-?)(.+)$/;
	$data->{style} = $2;
	$data->{reverse} = ($1 eq '-') ? 1 : 0;
	$data->{direction} = ($1 eq '-') ? -1 : 1;

	if ($data->{style} eq 'bar')
	{
		$data->{value} = 0;
	}
	elsif ($data->{style} eq 'dots')
	{
		$data->{value} = $data->{reverse} ? 0x88888888 : 0x11111111;
	}
	elsif ($data->{style} eq 'dashes')
	{
		$data->{value} = $data->{reverse} ? 0xcccccccc : 0x33333333;
	}
	elsif ($data->{style} eq 'bounce')
	{
		$data->{value} = $data->{reverse} ? 28 : 0;
	}
	else
	{
		return 0;
	}
	
	return 1;
};

sub threadhelper_animateBar
{
	my ($data) = @_;
	
	if ($data->{style} eq 'bar')
	{
		my $value = $data->{value};
		my $progress = $value/32;
		my $bits = makeProgressBar($progress);
		handle('bars', [$data->{bar}], $bits, 1);

		$value += $data->{direction};
		$value = -32 if ($value > 32);
		$value = 32 if ($value < -32);
		$data->{value} = $value;
	}
	elsif (($data->{style} eq 'dashes') || ($data->{style} eq 'dots'))
	{
		my $bits = $data->{value};
		handle('bars', [$data->{bar}], $bits, 1);

		if ($data->{reverse})
		{
			$data->{value} = (($bits << 1) & 0xfffffffe) | (($bits >> 31) & 0x00000001);
		}
		else
		{
			$data->{value} = (($bits >> 1) & 0x7fffffff) | (($bits << 31) & 0x80000000);
		};
	}
	elsif ($data->{style} eq 'bounce')
	{
		my $value = $data->{value};
		my $pos = $value/28;
		my $bits = makeScrollBar($pos);
		handle('bars', [$data->{bar}], $bits, 1);

		$value += $data->{direction};
		$data->{value} = $value;
		$data->{direction} = -$data->{direction} if (($value == 0) || ($value == 28));
	}
	else
	{
		print "Unhandled bar animation style: $data->{style}\n";
		return 0;
	};
	
	return 1;
};


return 1;
