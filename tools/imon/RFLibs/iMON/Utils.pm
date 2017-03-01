package RFLibs::iMON::Utils;
$RFLibs::iMON::Utils::VERSION = '1.00';

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
use Thread::Semaphore;
use Time::HiRes qw(usleep);

use RFLibs::iMON 1.00;
use RFLibs::Threads 1.00;

@RFLibs::iMON::Utils::ISA = qw(Exporter);
@RFLibs::iMON::Utils::EXPORT = qw(
			setupImonUtils
			cleanupImonUtils

			setProgressBar
			setScrollBar
			
			drawIntoBitmap
                      );


sub setupImonUtils
{
};

sub cleanupImonUtils
{
	thread_stop('animatebars');
};

#params = one or more pairs, each pair is (bar#, value) or ([$arrayref of bar#], value)
sub setProgressBar
{
	my @params;
	while(scalar(@_) >= 2)
	{
		my $bars = shift @_;
		$bars = [$bars] unless ref($bars); #if the param is a single value, turn it into an arrayref

		my $progress = shift @_;
		$progress = $1/100 if $progress =~ /^(-?\d+)%/;

		my $count = int(abs($progress)*32);
		my $bits = (2**$count) - 1;
		$bits <<= (32-$count) if ($progress > 0);
		
		push @params, $bars, $bits;
	};
	setBars(@params);
};

sub setScrollBar
{
	my @params;
	while(scalar(@_) >= 2)
	{
		my $bars = shift @_;
		$bars = [$bars] unless ref($bars); #if the param is a single value, turn it into an arrayref

		my $position = shift @_;
		$position = $1/100 if $position =~ /^(\d+)%/;

		my $shift = int($position*28);
		my $bits = 0xf0000000 >> $shift;

		push @params, $bars, $bits;
	};
	setBars(@params);
};

sub setBarAnimation
{
	my ($style, $rate) = @_;

	thread_stop('animatebars');
	thread_start('animatebars', \&threadbody_animateBars, $style, $rate);
}

sub threadbody_animateBars
{
	my ($style, $rate) = @_;
	my $delay = 1000000/$rate;
	
	while(1)
	{
		if ($style == 0)
		{
			foreach my $prog (-32..32)
			{
				return unless thread_running();
				my $val = $prog/32;
				setProgressBar([0,3], $val, [1,2], -$val);
				usleep($delay);
			};
		}
		elsif ($style == 1)
		{
			my $rbits = 0x33333333;
			my $lbits = 0xcccccccc;
			foreach my $prog (0..31)
			{
				return unless thread_running();
				setBars([0,3], $rbits, [1,2], $lbits);
				$rbits = (($rbits >> 1) & 0x7fffffff) | (($rbits << 31) & 0x80000000);
				$lbits = (($lbits << 1) & 0xfffffffe) | (($lbits >> 31) & 0x00000001);
				usleep($delay);
			};
		}
		elsif ($style == 2)
		{
			foreach my $pos (0..28, reverse(1..26))
			{
				return unless thread_running();
				setScrollBar([0,1,2,3], $pos/28);
				usleep($delay);
			};
		};
	};
};

sub drawIntoBitmap
{
	my ($src_bitmap, $dest_bitmap, $dest_x, $dest_y, $mask_height) = @_;

	my $src_length = length($src_bitmap)/2;
	my $dest_length = length($dest_bitmap)/2;

	my $count = $src_length;
	my $src_x = 0;
	if ($dest_x < 0)
	{
		$src_x = -$dest_x;
		$dest_x = 0;

		$count -= $src_x;
		$count = $dest_length if ($count > $dest_length);
	}
	else
	{
		$count = $dest_length-$dest_x if ($count > ($dest_length-$dest_x));
	};

	#determine which bits need to be masked out
	my $mask = (2**$mask_height - 1) << (16 - $mask_height);

	#go through each line, and rendery by ANDing with the mask then ORing with the shifted bitmap column
	my $source_index = 0;
	if ($dest_y < 0)
	{
		$mask = ~($mask << -$dest_y); 
		foreach my $i (0..$count-1)
		{
			
			my $src_column = unpack("S", substr($src_bitmap, 2*($src_x+$i), 2));
			my $dest_column = unpack("S", substr($dest_bitmap, 2*($dest_x+$i), 2));
			
			$dest_column = ($dest_column & $mask) | (($src_column << -$dest_y) & ~$mask);
			
			substr($dest_bitmap, 2*($dest_x+$i), 2) = pack("S", $dest_column);
		};
	}
	else
	{
		$mask = ~($mask >> $dest_y); 
		foreach my $i (0..$count-1)
		{
			my $src_column = unpack("S", substr($src_bitmap, 2*($src_x+$i), 2));
			my $dest_column = unpack("S", substr($dest_bitmap, 2*($dest_x+$i), 2));
			
			$dest_column = ($dest_column & $mask) | (($src_column >> $dest_y) & ~$mask);
			
			substr($dest_bitmap, 2*($dest_x+$i), 2) = pack("S", $dest_column);
		};
	};

	return $dest_bitmap;
};

return 1;



