#!/usr/local/bin/perl
# Time-stamp: Tue Jan 30 2007
#
use Tk;

$font1 = '-Adobe-Helvetica-Bold-R-Normal--*-240-*-*-*-*-*-*';
$font2 = '-Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-*';

my @hourNames = ("one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
        "ten", "eleven", "twelve");

my @normalFuzzy = ("%0 o'clock", "five past %0", "ten past %0", "quarter past %0",
        "twenty past %0", "twenty five past %0", "half past %0",  "twenty five to %1",
        "twenty to %1", "quarter to %1", "ten to %1", "five to %1", "%1 o'clock");

my @dayTime = ("Night",
        "Early morning",
        "Morning",
        "Almost noon",
        "Noon",
        "Afternoon",
        "Evening",
        "Late evening");

($sec,$min,$hour,$mday,$mon,$yr,$wday) = localtime(time);
my $month = $mon + 1;
my $year  = 1900 + $yr;
my $date = "$year-$month-$mday";
my $text = "";

my $mw = MainWindow->new;

$mw->title("Fuzzy Time");
$mw->Entry(-textvariable => \$text, -justify => 'center', -font => $font1)->pack(-fill => 'x');
$mw->Entry(-textvariable => \$date, -justify => 'center', -font => $font2)->pack(-fill => 'x');

my $fuzzyness = 1;
$mw->Scale(-from => 1, -to => 4, -variable => \$fuzzyness,
        -orient => "horizontal", -label => "Fuzzyness")->pack;

$mw->Button(-text => "Done", -command => sub { exit })->pack;

$mw->repeat(1000, \&addText);

MainLoop;

sub addText()
{
    my $lastSector = -1;
    ($sec,$min,$hour,$mday,$mon,$yr,$wday) = localtime(time);

    $month = $mon + 1;
    $year  = 1900 + $yr;
    $date = "$year-$month-$mday";

    if ($fuzzyness == 1 || $fuzzyness == 2)
    {
        $sector = 0;
        if ($fuzzyness == 1)
        {
            if ($min > 2)
            {
                $sector = int(($min - 3) / 5 + 1);
            }
        }
        else
        {
            if ($min > 6)
            {
                $sector = int((($min - 7) / 15 + 1)) * 3;
            }
        }

        $str = $normalFuzzy[$sector];
        $newHr = ($hour + 0) % 12;
        $hrStr = $hourNames[$newHr - 1];
        $str =~ s/\%0/$hrStr/;
        $newHr = ($hour + 1) % 12;
        $hrStr = $hourNames[$newHr - 1];
        $str =~ s/\%1/$hrStr/;

        $str = ucfirst($str);

        #print "$str\n" if $lastSector != $sector;
        $text = $str if $lastSector != $sector;

        $lastSector = $sector;
    }
    elsif ($fuzzyness == 3)
    {
        $text = $dayTime[$hour / 3];
    }
    elsif ($fuzzyness == 4)
    {
        if ($wday == 1)
        {
            $text = "Start of week";
        }
        elsif ($wday >= 2 && $wday <= 4)
        {
            $text = "Middle of week";
        }
        elsif ($wday == 5)
        {
            $text = "End of week";
        }
        else
        {
            $text = "Weekend!";
        }
    }
}
