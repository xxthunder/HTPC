package RFLibs::MythTV;
$RFLibs::MythTV::VERSION = '1.00';

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
use MythTV;
use vars qw(@ISA);
@ISA = ('MythTV');

sub ping 
{
	my ($self) = @_;
	return $self->{'dbh'}->ping();
}

sub keybinding
{
	my ($self, $context, $action, $host) = @_;
	$host = $self->{'hostname'} if ($host eq '');
	
	
	my $query  = 'SELECT keylist FROM keybindings WHERE context=? AND action=? AND hostname=?';
	my @params = ($context, $action, $host);
	
	my $sh = $self->{'dbh'}->prepare($query);
	$sh->execute(@params);
	my $result = $sh->fetchrow_array;
	$sh->finish;
	return wantarray ? split(/,/, $result) : $result;
};

sub getProgramInfo
{
	my ($self, $chanid, $starttime) = @_;
	
	my $query  = 'SELECT UNIX_TIMESTAMP(starttime) as starttime, UNIX_TIMESTAMP(endtime) as endtime, videoprop '.
			'FROM program WHERE chanid=? AND starttime=';
	
	if ($starttime =~ /\D/)
	{
		$starttime =~ s/T/ /g;
		$query .= '?';
	}
	else
	{
		$query .= 'FROM_UNIXTIME(?)';
	}
	my @params = ($chanid, $starttime);

	
	my $sh = $self->{'dbh'}->prepare($query);
	$sh->execute(@params);
	my $result = $sh->fetchrow_hashref;
	$sh->finish;

	$result->{hdtv} = ($result->{videoprop} =~ /HDTV/);
	
	return $result;
};

return 1;
