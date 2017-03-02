package RFLibs::LircMonitor;
$RFLibs::LircMonitor::VERSION = '1.00';

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
use Socket;
use Time::HiRes qw(gettimeofday);
use POSIX qw(floor);

my $defaultDevice = "/var/run/lirc/lircd";



sub SetError
{
	$RFLibs::LircMonitor::LastError = shift @_;
	return;
};

sub LastError
{
	return $RFLibs::LircMonitor::LastError;
};


sub new
{
	my ($classtype, $device) = @_;
	$device = $defaultDevice if $device eq ''; 

	my $self = [];
	bless $self, $classtype;
	
	socket($self->[0], PF_UNIX, SOCK_STREAM, 0) or return SetError("Cannot create socket: $!");
	connect($self->[0], sockaddr_un($device)) or return SetError("Cannot connect socket: $!");
	$self->[1] = {};
	$self->[1]->{device} = $device;
	$self->[1]->{events} = [];
	$self->[1]->{history} = [];

	return $self;
};


sub DESTROY
{
	my ($self) = @_;
	close($self->[0]);
};

sub clearHistory
{
	my ($self) = @_;
	$self->[1]->{history} = [];
};

sub addRepeatEvent
{
	my ($self, $name, $remote, $button, $repeat_count, $repeat_delay, $repeat_interval) = @_;
	
	my $event = [$name, 'repeat', lc($remote), lc($button), $repeat_count, $repeat_delay, $repeat_interval];
	push(@{$self->[1]->{events}}, $event);
};

sub addDurationEvent
{
	my ($self, $name, $remote, $button, $duration, $repeat_delay, $repeat_interval) = @_;
	
	my $event = [$name, 'duration', lc($remote), lc($button), $duration, $repeat_delay, $repeat_interval];
	push(@{$self->[1]->{events}}, $event);
};

sub addSequenceEvent
{
	my ($self, $name, $remote, $ary_sequence) = @_;
	my @sequence = reverse @$ary_sequence;
	foreach (@sequence) { lc; };
	my $event = [$name, 'sequence', lc($remote), \@sequence];
	push(@{$self->[1]->{events}}, $event);
};


sub readData
{
	my ($self) = @_;
	return sysread($self->[0], $self->[1]->{data}, 4096, length($self->[1]->{data})) 
};

sub nextEvent
{
	my ($self) = @_;
	my @events;
	my $data = $self->[1]->{data};

	while ($data =~ /^([^\r\f\n]+)[\r\f\n]+(.*)/s)
	{
		$data = $2;
		@events = $self->processLine($1);
		last if scalar(@events);
	};

	$self->[1]->{data} = $data;
	return @events;
};

sub processLine
{
	my ($self, $line) = @_;

	my ($code, $count, $button, $remote) = split(' ', $line);
	$remote = lc $remote;
	$button = lc $button;
	$count =  hex($count);

	#determine how long the button has been pressed
	my $time = scalar gettimeofday;
	if ($count == 0)
	{
		$self->[1]->{presstime} = $time;
		$self->[1]->{holdtime} = 0;
		$self->[1]->{lastholdtime} = -1;
	}
	else
	{
		$self->[1]->{lastholdtime} = $self->[1]->{holdtime};
		$self->[1]->{holdtime} = $time - $self->[1]->{presstime};
	};

	if ($self->[1]->{lastremote} ne $remote)
	{
		$self->[1]->{lastremote} = $remote;
		$self->[1]->{history} = [];
	};

	#keep a history of what buttons were pressed (ignore key repeats, 
	#but include when the user manually presses the key multiple times)
	#to keep it managable, limit the history to the last 100 buttons
	unshift(@{$self->[1]->{history}}, $button) if $count == 0;
	pop(@{$self->[1]->{history}}) if (scalar(@{$self->[1]->{history}}) > 100);

	my @event_list;
	foreach my $event (@{$self->[1]->{events}})
	{
		my ($event_name, $event_type, $event_remote) = @{$event}[0..2];

		next unless (($event_remote eq $remote) or ($event_remote eq '*'));
		if ($event_type eq 'repeat')
		{
			my ($event_button, $event_count, $event_delay, $event_interval) = @{$event}[3..6];
			next unless ($event_button eq $button);

			my $target = calcRepeatTarget($count, $event_count, $event_delay, $event_interval);
			next unless $count == $target;
		}
		elsif ($event_type eq 'duration')
		{
			my ($event_button, $event_duration, $event_delay, $event_interval) = @{$event}[3..6];
			next unless ($event_button eq $button);

			my $target = calcRepeatTarget($self->[1]->{holdtime}, $event_duration, $event_delay, $event_interval);
                        next if ($self->[1]->{lastholdtime} >= $target);
		}
		elsif ($event_type eq 'sequence')
		{
			next unless $count == 0;
			my $event_sequence = $event->[3];
			next unless $self->checkSequence($event_sequence);
        	};
		
		push(@event_list, $event_name);
	};
	return @event_list;
}

sub calcRepeatTarget
{
	my ($elapsed, $first, $delay, $interval) = @_;
	return -1 if ($elapsed < $first);
	return $first if ($interval <= 0);
	return $first if ($elapsed < ($first+$delay));

	my $x = floor(($elapsed-$first-$delay)/$interval);
	$x = 0 if $x < 0;

	return $first + $delay + ($interval * $x);
};

#see if a sequence of button presses has ocurred
sub checkSequence
{
	my ($self, $sequence) =  @_;
	my $history = $self->[1]->{history};

	#if there aren't enough buttons in the history, no point in looking
	return 0 if $#$history < $#$sequence;

	#see if each button matches
	for(my $i=0; $i<=$#$sequence; $i++)
	{
		return 0 unless $history->[$i] eq $sequence->[$i];
	};

	#if we got here, everything matched up...were done
	return 1;
};

return 1;
