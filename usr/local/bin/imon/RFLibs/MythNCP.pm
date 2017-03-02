package RFLibs::MythNCP;
$RFLibs::MythNCP::VERSION = '1.00';

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
use RFLibs::TransactionSocket 1.00;
use vars qw(@ISA);

@ISA = ('RFLibs::TransactionSocket');

my $defaultPort = 6546;
my $response_terminator = chr(13).chr(10)."# ";


sub init
{
	my ($self, %options) = @_;

	my $host = $options{'Host'} || 'localhost';
	my $port = $options{'Port'} || $defaultPort;
	my $keepopen = defined($options{'KeepOpen'}) ? $options{'KeepOpen'} : 1;
	my $delayconnect = defined($options{'DelayConnect'}) ? $options{'DelayConnect'} : 0;

	$self->{rawresponse} = $options{'RawResponse'} || 0;
	$self->{connect_response} = '';
	$self->{last_response} = '';

	$self->SUPER::init(
			Host => $host, 
			Port => $port, 
			KeepOpen => $keepopen, 
			DelayConnect => $delayconnect
			) or return 0;

	return $self;
};

sub connect
{
	my ($self) = @_;
	
	$self->SUPER::connect() or return 0;

	$self->read() or return 0;

	$self->{connect_response} = $self->{last_response};
	$self->{last_response} = '';

	return 1;
};

sub processRead
{
	my ($self, $dataref) = @_;
	return 0 unless (substr($$dataref, -4) eq $response_terminator);
	
	#if desired, string the trailing "# " but leave the CRLF before it
	$self->{last_response} = $self->{rawresponse} ? $$dataref : substr($$dataref, 0, -2); 
	return 1;	
};

sub process_single
{
	my ($self, $command) = @_;

	#make sure this is only 1 command, otherwise we run into trouble
	($command) = split(/[\n\r\f]+/m, $command, 2);		

	
	#if we have something to read, we may have disconnected...lets find out
	$self->read() if $self->{select}->can_read(0);

	
	$self->{connected} or $self->connect() or return 0;
	$self->write($command."\n\n") or return 0;

	my $result = $self->read();
	if (!$result)
	{
		#if we didn't disconnect, who knows what?
		return 0 if $self->{connected};
		
		#of course we disconnected...issued quit or exit command
		return 1 if $command =~ /^\s*(quit|exit)(\s|$)/i;
		
		#reconnect and try again
		$self->connect() or return 0;			
		$self->write($command) or return 0;
		$result = $self->read();
	};
	
	return $result;
};

sub process
{
	my ($self, @commands) = @_;
	my $count = 0;

	foreach my $command (@commands)
	{
		foreach my $subcommand (split(/[\n\r\f]+/m, $command))
		{
			$self->process_single($subcommand) or return $count;
			$count++;
		};
	};
	
	return $count;
};

sub connect_response
{
	my ($self) = @_;
	return $self->{connect_response};
}

sub response
{
	my ($self) = @_;
	return $self->{last_response};
};


#issues a 'query location' command via the network control port and returns the 1st word of the response (which usually identifies the locaiton)
#if the location is playback and the function was called in array context, the second return value with be a hash reference with additional
#information about the playback state (recorded or live tv, postion, recorded length, playback speed, etc)
sub location
{
	my ($self) = @_;
	my %data;
	
	#occasionally it fails, so try again to be sure
	$self->process('query location') or $self->process('query location') or return;

	my $line = $self->response();
	if ($line =~/^playback /i)
	{
		return 'playback' unless wantarray;

		my ($remainder, $token);

		($data{location}, $data{mode}, $remainder) = split(' ', $line, 3);
		($data{menutype}, $remainder) = split(' ', $remainder, 2) if $remainder =~ /^(Title|Root|Subpicture|Audio|Angle|Part)/i;
		($data{position}, $remainder) = split(' ', $remainder, 2) if $remainder =~ /^\d+:\d+:\d+/;
		(undef, $data{length}, $remainder) = split(' ', $remainder, 3) if $remainder =~ /^of \d+:\d+:\d+/;
		($data{speed}, $remainder) = split(' ', $remainder, 2) if $remainder =~ /^-?\d+(\.\d+)?X/;
		($data{chanid}, $data{starttime}, $remainder) = split(' ', $remainder, 3) if $remainder =~ /^\d+ \d+-\d+-\d+T\d+:\d+:\d+/;
		($data{framesplayed}, $remainder) = split(' ', $remainder, 2) if $remainder =~ /^\d+ /;
		if ($remainder =~ /(.*) (?:(\d+) )([0-9.]+)\s*$/)
		{
			$data{filename} = $1;
			$data{framesplayed} = $2 if ($2 > 0);
			$data{framerate} = $3;
		};

		$data{location} = lc($data{location});
		$data{mode} = lc($data{mode});
		$data{menutype} = lc($data{menutype});

		return ($data{location}, %data);
	};

	$line =~ /^([^ \r\n\f]*)/;
	return lc($1);
};

#special wrapper for the location function to specifically handle playback mode
#if called without a parameter, simply checks if frontend is in playback
#if a paramater of either 'livetv' or 'recorded' is passed in, it checks if it's playing in that mode
sub inPlayback
{
	my ($self, $required_mode) = @_;

	return $self->inScreen('playback', $required_mode);
};

sub inScreen
{
	my ($self, $screen, $required_playback_mode) = @_;
	$screen = lc $screen;
	$required_playback_mode = lc $required_playback_mode;
	
	my ($location, %data) = $self->location();
	return 0 if ($location ne $screen);
	return 0 if (($screen eq 'playback') && ($required_playback_mode ne '') && ($required_playback_mode ne $data{mode}));
	return 1;
}


my %translation_table = (
	'esc' => 'escape',
	'del' => 'delete',
	'ins' => 'insert',
	'pgup' => 'pageup',
	'pgdown' => 'pagedown',
);

sub translateKey
{
	shift(@_) if ref($_[0]); #allow this to be called directly or via an instance
	my $key = lc shift @_;
	
	return $translation_table{$key} if exists $translation_table{$key};
	return $key;
}

return 1;
