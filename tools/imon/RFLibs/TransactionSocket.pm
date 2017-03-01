package RFLibs::TransactionSocket;
$RFLibs::TransactionSocket::VERSION = '1.00';

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
use IO::Socket::INET;
use IO::Select;

sub new
{
	my ($classtype, %options) = @_;
	
	my $self = {};
	bless $self, $classtype;

	return $self->init(%options);
};

sub init
{
	my ($self, %options) = @_;
	
	$self->{host} = defined($options{'Host'}) ? $options{'Host'} : 'localhost';
	$self->{port} = $options{'Port'} or return 0;;
	$self->{keepopen} = defined($options{'KeepOpen'}) ? $options{'KeepOpen'} : 1;
	$self->{delayconnect} = defined($options{'DelayConnect'}) ? $options{'DelayConnect'} : 1;
	
	$self->{socket} = undef;
	$self->{connected} = 0;

	$self->{select} = new IO::Select;

	$self->{connect_response} = '';
	$self->{last_response} = '';

	if ($self->{keepopen} && !$self->{delayconnect})
	{
		$self->connect() or return 0;	
	};

	return $self;
};


sub DESTROY
{
	my ($self) = @_;
};



sub connect
{
	my ($self) = @_;
	
	return 1 if $self->{connected};

	$self->{socket} = new IO::Socket::INET(PeerAddr =>$self->{host}.":".$self->{port} , ReuseAddr => 1) or return 0;
	$self->{select}->add($self->{socket});
	$self->{connected} = 1;
	
	return 1;
};

sub disconnect
{
	my ($self) = @_;
	return 1 unless $self->{connected};
	
	$self->{select}->remove($self->{socket});
	my $result = $self->{socket}->close();
	$self->{socket} = undef;
	$self->{connected} = 0;

	return $result;
}

sub reconnect
{
	my ($self) = @_;
	$self->disconnect();
	return $self->connect();
}

sub read
{
	my ($self) = @_;
	return 0 unless $self->{connected};

	my $data = '';
	while(!$self->processRead(\$data))
	{
		my ($socket) = $self->{select}->can_read(5);
		if ($socket == $self->{socket})
		{
			my $count = $self->{socket}->sysread($data, 1024, length($data));
		
			next if $count > 0;
		
		};
		$self->disconnect();
		return 0;
	};

	return 1;
}

sub write
{
	my ($self, $data) = @_;

	return 0 unless $self->{connected};
	
	my ($socket) = $self->{select}->can_write(5);
	return 0 if ($socket != $self->{socket});

	my $count = $self->{socket}->syswrite($data);

	return $count == length($data);
}

sub isConnected
{
	my ($self) = @_;
	return $self->{connected};
};


return 1;
