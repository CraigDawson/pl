#!/usr/bin/perl -w

use strict;
use warnings;
use threads;
use threads::shared;



$| = 1;
my $percent:	shared = 0;
my $lock:	shared = 0;
my $done:	shared = 0;

sub CopyFileProgress ( ) {
	my	$src 	= shift;
	my	$dst	= shift;
	my	$num_read;
	my	$num_wrote;
	my	$buffer;
	my	$perc_done = 0;
	
	#print "src=$src, dst=$dst\n";

	open (SRC, "< $src") or die "Could not open source file [$src]: $!\n";
	open (DST, "> $dst") or die "Could not open destination file [$dst]: $!\n";
	binmode SRC;
	binmode DST;
	
	my 	$filesize = (-s $src) or die "File has zero size.\n";
	my	$blksize  = int ($filesize / 20);
	
	while (1) {
		$num_read = sysread(SRC, $buffer, $blksize);
		if ($num_read == 0)
		{
			$done = 1;
			last;
		} 										
		die ("Error reading from file [$src]: $!\n") if (!defined($num_read));	

		my $offset = 0;
		while ($num_read){
			$num_wrote = syswrite(DST,$buffer,$num_read,$offset);
			die ("Error writing to file [$dst]: $!\n") if (!defined($num_wrote));
			$num_read -= $num_wrote;
			$offset	+= $num_wrote;
		}

		$perc_done += 5 unless $perc_done == 100;
		if ($lock == 0)
		{
			$percent = $perc_done;
			$lock = 1;
		}
	}	
}

my $mw;
my $percentDisplay = 0;
use Tk;
use Tk::ProgressBar;

if (@ARGV == 2) {
	my	$source		= shift @ARGV;
	my	$destination 	= shift @ARGV;
	my	$thread 	= threads->new(\&CopyFileProgress, $source, $destination);

        #print "thread started\n";

	$mw=MainWindow->new;

	my $pb=$mw->ProgressBar(
			-height      => 0,
			-width       => 40,
			-length      => 200,
			-colors=>[0,'green'],
			-blocks=>100,
			-variable=>\$percentDisplay)->pack;


	$mw->repeat(100, \&show_progress);

	MainLoop;

	#while (1)
	#{
	#	last if $done;

	#	if ($lock == 1)
	#	{
	#		print "\r$percent% complete";
	#		$lock = 0;
	#	}
	#	sleep(1);
	#}
	$thread->join;
	print "\r100% completed\n";

}else{
	print "\n\nUSAGE: copyTk.pl <source filename> <destination filename>\n\n";
}

1;

sub show_progress{
	if ($lock == 1)
	{
		$percentDisplay = $percent;
		$mw->update();
		$lock = 0;
	}

	if ($done)
	{
		$mw->destroy();
	}
}

