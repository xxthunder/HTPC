package RFLibs::Threads;
$RFLibs::Threads::VERSION = '1.00';

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

@RFLibs::Threads::ISA = qw(Exporter);
@RFLibs::Threads::EXPORT = qw(
			thread_start
			thread_stop
			thread_running
                      );


my $threadsStarting = 0;
my %threadsByName;
my %threadsById;

share($threadsStarting);
share(%threadsByName);
share(%threadsById);

#starts up a thread
sub thread_start
{
	my ($name, $func, @args) = @_;

	$threadsStarting++;
	my $thread = new threads($func, @args);
	$threadsByName{$name} = $thread->tid();
	$threadsById{$thread->tid()} = $name;
	$threadsStarting--;
};

#stops a thread
sub thread_stop
{
	my ($name, $no_wait) = @_;
	my $tid = $threadsByName{$name};
	return unless $tid;

	my $thread = threads->object($tid);
	delete $threadsByName{$name};
	delete $threadsById{$tid};

	return $thread->detach() if $no_wait;
	return $thread->join();
};

#can be called to determine if a thread is allowed to continue running
#threads should call this periodically to decide if they need to exit
#in response to someone calling thread_stop
sub thread_running
{
	my ($tid) = @_;
	$tid = threads->tid() unless defined $tid;
	
	#in theory, if a thread calls thread_running right after starting, but before it's info
	#has been fully logged, it could mistakenly think it has been asked to stop, so to make
	#sure this race condition doesn't happen, we will wait until all thread starting have been
	#fully started and logged.
	while($threadsStarting)
	{
		threads->yield();
	};
	
	return exists($threadsById{$tid});
};
