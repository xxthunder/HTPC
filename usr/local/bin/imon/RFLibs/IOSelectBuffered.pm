package RFLibs::IOSelectBuffered;
$RFLibs::IOSelectBuffered::VERSION = '1.00';

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
use vars qw(@ISA);

@ISA = ('IO::Select');


my %selects;

sub new
{
	require IO::Select;

	my ($classtype, @handles) = @_;

	my $self = new IO::Select();
	ref($self) or return $self;
	bless $self, $classtype;
	
	$selects{$self} = {};
	$self->add(@handles);
	
	return $self;
};


sub DESTROY
{
	my ($self) = @_;
	delete $selects{$self};
	
	$self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
};

sub add
{
	my ($self, @handles) = @_;
	foreach my $handle (@handles)
	{
		$selects{$self}->{$handle} = {};
		$selects{$self}->{$handle}->{data} = '';
		$selects{$self}->{$handle}->{lines} = [];
	};
	
	return $self->SUPER::add(@handles);
};

sub remove
{
	my ($self, @handles) = @_;
	foreach my $handle (@handles)
	{
		delete $selects{$self}->{$handle};
	};
	
	return $self->SUPER::remove(@handles);
};


sub can_read
{
	my $self = shift @_;
	
	my @handles;
	
	my $handles = $selects{$self};
	foreach my $handle ($self->handles())
	{
		my $buffer = $selects{$self}->{$handle};
		push(@handles, $handle) if ref($buffer) && scalar(@{$buffer->{lines}});
	};
	
	return @handles if scalar(@handles);
	
	return $self->SUPER::can_read(@_);
};


sub getline
{
	my ($self, $handle) = @_;

	my $buffer = $selects{$self}->{$handle};
	
	return shift @{$buffer->{'lines'}} if scalar @{$buffer->{'lines'}};
	
	my $count = sysread($handle, $buffer->{data}, 4096, length($buffer->{data}));
	return unless $count;


	my $pos = index($buffer->{data}, "\n");
	while($pos != -1)
	{
		my $line = substr($buffer->{data}, 0, $pos+1, '');
		push(@{$buffer->{lines}}, $line);
		$pos = index($buffer->{data}, "\n");
	};

	return shift @{$buffer->{'lines'}} if scalar @{$buffer->{'lines'}};
	return '';
};

return 1;
