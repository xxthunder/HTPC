package RFLibs::ProportionalText;
$RFLibs::ProportionalText::VERSION = '1.00';

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

@RFLibs::ProportionalText::ISA = qw(Exporter);
@RFLibs::ProportionalText::EXPORT = qw(
			wrapText
                      );

#split the text into pieces, each piece being either entierly non-spaces or 
#entirely spaces. Also calculate the width of each piece
sub splitWords
{
	my ($text, $charwidths, $pieces, $widths) = @_;

	while($text =~ /\G([^ ]+| +)/g)
	{
		my $piece = $1;
		my $width = calculateTextWidth($piece, $charwidths);

		push(@$pieces, $piece);
		push(@$widths, $width);
	};
};

sub wrapText
{
	my ($text, $charwidths, $maxwidth, $minwidth, $min_hyphenation) = @_;
	

	my @lines;

	#split on newlines so that we can force the text to wrap
	foreach my $textline (split("\n", $text))
	{
		#special case handling for blank or all space lines	
		if ($textline =~ /^ *$/)
		{
			push (@lines, '');
			next;
		};
	
		#split the current line into pieces, each piece being either entierly non-spaces or 
		#entirely spaces. Also calculate the width of each piece
		my (@pieces, @widths);
		splitWords($textline, $charwidths, \@pieces, \@widths);
		
		
		#now start building our wrapped text one line at a time, until we run out of pieces
		my $line = '';
		my $linewidth = 0;
		my $firstpiece = 1;
		while(scalar(@pieces))
		{
			#get the next piece and its width
			my $piece = shift @pieces;
			my $piecewidth = shift @widths;

			#process the current piece
			foreach (1)
			{
							
				#if it will fit on the current line, add it and move onto the next piece
				if (($linewidth + $piecewidth) < $maxwidth)
				{
					$line .= $piece;
					$linewidth += $piecewidth;
					last;
				};

				#if it's whitespace, who cares if it doesn't fit...discard it and end the line
				if ($piece =~ / /)
				{
					push(@lines, $line);
					$line = '';
					$linewidth = 0;
					last;
				};

				#if our line has reached the minumum width, theres no need to force hyphenation.
				#just save the current line, reset it it, and then let the split handling below
				#take care of the rest.
				#HOWEVER, if the piece will not fit entirely on the next line (ie: it's longer than the maxwidth)
				#it's going to need to be hyphenated anyway, so we might as well take advantage of the space we 
				#have left on this line
				if (($linewidth >= $minwidth) && ($piecewidth <= $maxwidth))
				{
					push(@lines, $line);
					$line = $piece;
					$linewidth = $piecewidth;
					last;
					
				};

				#figure out how much room we have on this line, including the hyphen
				my $available = $maxwidth - $linewidth - $charwidths->{'-'};


				#it would look dumb to have just a few chars and a hyphen.if we can't fit at least 
				#the requested number of chars on this line, don't even try
				#(trick the code below into thinking no available is space)
				my $w = calculateTextWidth(substr($piece,0,$min_hyphenation), $charwidths);
				$available = 0 if ($w > $available);

				
				#split the remainder into chars, and see how much we can fit onto the line
				my @chars = split('', $piece);
				my $charsadded = 0;
				while(scalar(@chars))
				{
					my $char = shift(@chars);
					my $charwidth = $charwidths->{$char};
				
					#if the char fits, add it and goto the next char
					if ($available >= $charwidth)
					{
						$line .= $char;
						$available -= $charwidth;
						$piecewidth -= $charwidth;
						$charsadded++;
						next;
					};
					
					#we've run out of room on the line. Tack on the hyphen (if appropriate)
					$line .= '-' if $charsadded;
					
					#save the line, and then start over processing the remainer of the piece 
					#as if it were a whole piece
					push(@lines, $line);
					$line = '';
					$linewidth = 0;
					$piece = join('', $char, @chars);
					last;
				};
				
				#if there is still part of this piece, restart the handling on a new line
				redo if scalar(@chars);
			};
		};
		
		#whatever we have left over is its own line
		push(@lines, $line) if ($line ne '');
	}
	
	return @lines;
};

sub calculateTextWidth
{
	my ($text, $charwidths) = @_;
	
	my $width = 0;
	foreach my $char (split('', $text))
	{
		$width += $charwidths->{$char};
	};
	return $width;
}

return 1;



