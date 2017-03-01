package RFLibs::iMON::Menu;
$RFLibs::iMON::Menu::VERSION = '1.00';

################################################################################
#
#	Created by Ronald Frazier
#	http://www.ronfrazier.net
#
#       Feel free to do anything you want with this, as long as you
#       include the above attribution.
#
################################################################################


use strict;
use threads;
use threads::shared;
use Thread::Semaphore;
use Time::HiRes qw(usleep);

use RFLibs::iMON 1.00;
use RFLibs::iMON::Utils 1.00;
use RFLibs::iMON::Text 1.00;
use RFLibs::Threads 1.00;
use RFLibs::ProportionalText 1.00;

@RFLibs::iMON::Menu::ISA = qw(Exporter);
@RFLibs::iMON::Menu::EXPORT = qw(
			setupImonMenu
			cleanupImonMenu
			setMenu

			
                      );


my $force_update : shared = 1;


my $RunImonMenu = new Thread::Semaphore(0);

sub setupImonMenu
{
	createScreen('imonmenu', 'none', 'none');
	createTextArea('imonmenu_s1', '5px', 'smooth', 'loop', 'center');
	createTextArea('imonmenu_s2', '5px', 'smooth', 'loop', 'center');
	createTextArea('imonmenu_s3', '5px', 'smooth', 'loop', 'center');
	createTextArea('imonmenu_s4', '5px', 'smooth', 'loop', 'center');
	createTextArea('imonmenu_b', 'smallcaps', 'smooth', 'loop', 'center');

	setAreaText('imonmenu_s1', 'Selected - 1');
	setAreaText('imonmenu_s2', 'Selected Item');
	setAreaText('imonmenu_b', 'Selected + 1');

	thread_start('imonmenu', \&threadbody_imonMenu);
	$RunImonMenu->up;
};


sub cleanupImonMenu
{
	thread_stop('imonmenu', 1);
	$RunImonMenu->up;
};


sub setMenu
{
	my ($index, @items) = @_;
	
	setAreaText('imonmenu_s1', $items[$index-1]);
	setAreaText('imonmenu_s2', $items[$index+1]);
	setAreaText('imonmenu_b', $items[$index]);
	
	$force_update = 1;
};






sub threadbody_imonMenu
{
	my $last_bitmap;
	my $transition_steps = 0;
	while(1)
	{
		$RunImonMenu->down;

		last unless thread_running();

		my @areas = RFLibs::iMON::Text::getAreasByName('imonmenu_s1', 'imonmenu_b', 'imonmenu_s2');

		my $now = Time::HiRes::time();
		
		$transition_steps = 15 if $force_update;
		$force_update = 0;

		my $redraw = $transition_steps;
		$transition_steps-=3 if $transition_steps > 0;

		$redraw |= RFLibs::iMON::Text::scrollText_handleItems(\@areas, $now);
		next unless $redraw;

		my $bitmap = RFLibs::iMON::Text::generateBitmapBinary(-1, @areas);

		if ($transition_steps && $last_bitmap)
		{
			my $blank = pack("S",0) x 96;
			$bitmap = drawIntoBitmap($bitmap, $blank, 0, 0, 16-$transition_steps);
		};
		
		$last_bitmap = $bitmap unless $transition_steps;

		$bitmap = RFLibs::iMON::Text::bitmapBinaryToImon($bitmap);
		setBitmap($bitmap);

#		my @col = unpack("S*", $bitmap);
#		print scalar(@col),"\n";



		
	}
	continue
	{
		usleep(100000) unless $transition_steps;
		$RunImonMenu->up;
	};
};




return 1;
