package RFLibs::Aquos;
$RFLibs::Aquos::VERSION = '1.00';

################################################################################
#
#       Created by Ronald Frazier
#       http://www.ronfrazier.net
#
#       Feel free to do anything you want with this, as long as you
#       include the above attribution.
#
################################################################################

use strict;
use Device::SerialPort;
use Time::HiRes qw(sleep);

my %debuglevels = ('NONE' => 0, 'ERROR' => 1 , 'WARN' => 2, 'INFO' => 3);

sub new
{
        my ($classtype, $serialport_device) = @_;

        my $self = {};
        bless $self, $classtype;

        return $self->init($serialport_device);
};

sub init
{
	my ($self, $serialport_device) = @_;

	my $port = Device::SerialPort->new($serialport_device) or return 0;
	$port->baudrate(9600);
	$port->parity("none");
	$port->databits(8);
	$port->stopbits(1); 
	$port->handshake("none");
	$self->{port} = $port;

	$self->debug('WARN');

	return $self;
};

sub debug
{
	my ($self, $debug) = @_;
	$self->{debug} = $debug if defined($debug);
	return $self->{debug};
};

sub debugprint
{
	my ($self, $level, @msg) = @_;
	return if $debuglevels{$self->{debug}} < $debuglevels{$level};
	print STDERR @msg;
};

sub enable_serial_powerup
{
	my ($self, $value) = @_;
	return $self->set('RSPW', optbool($value,1,0));
};

sub power
{
	my ($self, $value) = @_;
	return $self->getset('POWR', optbool($value,1,0));
};

sub volume
{
	my ($self, $value) = @_;
	return $self->getset('VOLM', $value);
};

sub adjust_volume
{
	my ($self, $adjust) = @_;
	my $current = $self->get('VOLM');
	return 'ERR' if $current eq 'ERR';

	#this is to help figure out a rare bug that shows up where the volume jumps to 1/0  when trying to adjust it up/down
	#this may have been eliminated by my check for non-ASCII characters in sendCommand, but I'm leaving it for now just in case
	if ($current == 0)
	{
		my $current2 = $self->get('VOLM');
		if ($current2 ne $current)
		{
			$self->debugprint('ERROR', "Volume query returned 2 different values: '$current' and '$current2'\n");
		};
	};

	my $new = $current + $adjust;
	$new = 0 if ($new < 0);
	$new = 60 if ($new > 60);
	return $new if ($self->set('VOLM', $new) ne 'ERR');
	return 'ERR';
};

sub mute
{
	my ($self, $value) = @_;
	return $self->getset('MUTE', optbool($value,1,2));
};

sub toggle_mute
{
	my ($self) = @_;
	return $self->getset('MUTE', 0);
};

sub input
{
	my ($self, $value) = @_;
	if (!defined($value))
	{
		return '' unless $self->power();
		my $input = $self->get('IAVD');
		return $input unless ($input eq 'ERR');
		return '0';
	}
	return $self->set('ITVD', 0) if ($value eq '0');
	return $self->set('IAVD', $value);
};

sub optbool
{
	my ($value, $true, $false) = @_;
	return unless defined($value);
	return $value ? $true : $false;
};

sub get
{
	my ($self, $cmd) = @_;
	return $self->sendCommand("$cmd?   ");
};

sub set
{
	my ($self, $cmd, $value) = @_;
	$value .= ' ' while(length($value) < 4);
	return $self->sendCommand("$cmd$value");
};

sub getset
{
	my ($self, $cmd, $value) = @_;
	return $self->get($cmd) unless defined($value);
	return $self->set($cmd, $value);
};


sub sendCommand
{
	my ($self, $cmd) = @_;
	foreach (1..3)
	{
		my $result = $self->sendCommand_inner($cmd);
		if ($result eq 'BUSY')
		{
			$self->debugprint('WARN', "Return value for $cmd was BUSY...retrying in 1/4 second\n");
			sleep(0.25);
			redo;
		};
		$self->debugprint('INFO', "ERR\n") if $result eq 'ERR';
		next if $result eq 'ERR';
		return 'ERR' if $result eq 'NORESPONSE';

		#occasionally we get non-ascii characters mixed in with the data. If so, we need to reprompt
		if ($result =~ /([^a-zA-Z0-9_\- ])/)
		{
			$self->debugprint('ERROR', "Received non ASCII character in response: '$1' Hex=".ord($1)."\n");
			redo;
		};

		return $result;
	};
	return 'ERR';
};

sub sendCommand_inner
{
	my ($self, $cmd) = @_;
	$self->debugprint('INFO', "\t\t$cmd\n");

	#clear the buffer
	while(1)
	{
		my ($bytes, $read) = $self->{port}->read(1);
		last if $bytes == 0;
		$self->debugprint('WARN', "$bytes byte(s) -->$read<-- cleared from buffer\n");
	};


	$self->{port}->write("$cmd\r");

	my $data = '';
	my $start = Time::HiRes::time();
	while(1)
	{
		if ((Time::HiRes::time() - $start) >= 1)
		{
			$self->debugprint("WARN", "read timeout with partial data: -->$data<--\n") if ($data ne '');
			return 'NORESPONSE';
		};

		my ($bytes, $read) = $self->{port}->read(1);
		next if $bytes == 0;
		return $data if ($read eq "\r");
		$data .= $read;
	};	
};

return 1;
