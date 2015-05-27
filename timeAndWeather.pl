# Time-stamp: Thu Dec 09 2010 EST
#
# Uses some code from Milivoj Ivkovic's uptime V0.26 (CPAN script)
#
use strict;
use warnings;
use Tk;
use Geo::WeatherNOAA;
#require "ctime.pl";
use POSIX;
use LWP::Simple;
use Tk::DialogBox;
use Tk::Clock;
use Weather::Underground;

my $weatherUG = Weather::Underground->new(
		place => "Boston, MA",
		debug => 0,
		)
|| die "Error, could not create new weather object: $@\n";

my $arrayref = $weatherUG->get_weather()
	|| die "Error, calling get_weather() failed: $@\n";

print "Temp: " . $arrayref->[0]->{temperature_fahrenheit} . "\n";

#my $url="http://radar.weather.gov/Conus/RadarImg/latest_Small.gif";
my $url="http://radar.weather.gov/Conus/RadarImg/northeast.gif";
#my $file="latest_Small.gif";
my $file="northeast.gif";

create_ui();

MainLoop();

1;

#-------------------------------------------------------------------
my $top;                        # Main window
my $text0;                      # Current Time and Internet Time
my $text1;                      # GMT
my $text2;                      # UpTime text widget
my $text3;                      # Weather text widget
my $minutes = 0;                # inc once a minute
my $debug   = 0;                # 1 for debug prints to console
my $image;                      # weather map

sub create_ui
{
	getWeatherMap();

	$top = MainWindow->new();

# MENU STUFF

# Menu bar
	my $menu_bar = $top->Frame()->pack('-side' => 'top', '-fill' => 'x');

# TEXT STUFF
	$text0 = $top->Text('-width' =>  80, 
			'-height' => 1,
			'-font' => "-*-Courier-Medium-R-Normal--*-170-*-*-*-*-*-*"
			)->pack('-side' => 'top');

	$text1 = $top->Text('-width' =>  80, 
			'-height' => 1,
			'-font' => "-*-Courier-Medium-R-Normal--*-170-*-*-*-*-*-*"
			)->pack('-side' => 'top');

	$text2 = $top->Text('-width' =>  80, 
			'-height' => 1,
			'-font' => "-*-Courier-Medium-R-Normal--*-170-*-*-*-*-*-*"
			)->pack('-side' => 'top');

	$text3 = $top->Text('-width' =>  80, 
			'-height' => 4,
			'-font' => "-*-Courier-Medium-R-Normal--*-170-*-*-*-*-*-*"
			)->pack('-side' => 'top');

	$image = $top->Photo(-file=>$file, -width=>600, -height=>571);
	$top->Button(-image=>$image,
			-width=>600,
			-height=>571,
			-command => sub
			{ 
			my $dialogA = $top->DialogBox( -title   => "About This Image",
				-buttons => [ "OK" ],
				);

			$dialogA->add("Label",

				-borderwidth => '2',
				-background => "#FAEBD7", #ANTIQUE WHITE
				-font => 'bold',
				-justify => 'left',
				-relief => 'sunken',
				-text => "This Image is Produced by:\n National Weather Service NOAA\n http://radar.weather.gov/Conus/index.php \nThis image is updated every 10 minutes.")->pack;

### --- Prevents Dialog Box Resizing
			$dialogA->bind('<Configure>' => sub{
				my $xeD = $dialogA->XEvent;
				$dialogA->maxsize($xeD->w, $xeD->h);
				$dialogA->minsize($xeD->w, $xeD->h);
				});
			$dialogA->Show;
			}
	)->pack('-side' => 'left');

	my $c = $top->Clock->pack (-side => 'right', -expand => 1, -fill => "both");
	$c->config (anaScale  => 200)->config (anaScale => 0);
	$c->config (
			useDigital	=> 0,
			useAnalog	=> 1,
			secsColor	=> "Red",
			handColor	=> "Black",
			handCenter	=> 1,
		   );

# TIE
	tie (*TEXT0,  'Tk::Text', $text0);
	tie (*TEXT1,  'Tk::Text', $text1);
	tie (*TEXT2,  'Tk::Text', $text2);
	tie (*TEXT3,  'Tk::Text', $text3);

	initialize();

	$top->repeat(1000, \&update1s);

	$top->repeat(60000, \&update60s);
}

sub update1s
{
    #
    # GMT
    #
    my $secGMT;
    my $minGMT;
    my $hourGMT;
    my $mdayGMT;
    my $monGMT;
    my $yearGMT;
    my $wdayGMT;
    my $ydayGMT;
    my $isdstGMT;

    ($secGMT, $minGMT, $hourGMT, $mdayGMT, $monGMT,
	$yearGMT, $wdayGMT, $ydayGMT, $isdstGMT) = gmtime;

    my $mname = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
	"Aug", "Sep", "Oct", "Nov", "Dec")[$monGMT];

    my $dname = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri",
	"Sat")[$wdayGMT]; 

    #
    # Internet Time
    # 
    my $ihour = $hourGMT + 1;
    $ihour %= 24;

    my $isecs = ($ihour * 3600) + ($minGMT * 60) + $secGMT;
    my $it2 = $isecs / 86.4;
    #my $itr = $isecs * 0.01157;

    #
    # Output
    #
    $text0->delete('1.0', 'end');
    $text1->delete('1.0', 'end');
    $text2->delete('1.0', 'end');

    my $local = &ctime(time);
    chomp($local);
    printf TEXT0 "Local:  %s", $local;

    printf TEXT1 "GMT:    %s %s %2d %02d:%02d:%02d %d         Inet: @%03d", # .%02d",
    $dname, $mname, $mdayGMT, $hourGMT, $minGMT, $secGMT, $yearGMT + 1900, $it2; #, $itr;

    my $ut = `uptime`;
    chomp($ut);
    printf TEXT2 "$ut";
}

sub initialize
{
    my $buf = sprintf "Time And Weather 1.0";
    $top->title($buf);

    $text3->delete('1.0', 'end');
    my $weather = getForecast();
    print TEXT3 $weather;
}

sub update60s
{
    my $res = 10;

    $minutes++;
    if (($minutes % $res) == 0)
    {
	$text3->delete('1.0', 'end');
	my $weather = getForecast();
	print TEXT3 $weather;

	getWeatherMap();
	$image->blank; #clear out old image
	$image->read($file);

    }
}

sub getWeatherMap
{
    my $t = localtime(time);
    chomp($t);
    print "$t   Getting weather map . . ." if $debug;
    my $status=getstore($url, $file);
    warn "$status=getstore($url, $file)\n" if (is_error($status));
    print " done.\n" if $debug;
}

sub getForecast()
{
    my $t = localtime(time);
    chomp($t);
    print "$t   Getting forecast . . . " if $debug;
    my $weather = print_current('boston', 'ma', '', 'get');
    $weather =~ s/\&deg\;/\xb0/;
    print "done.\n" if $debug;
    return $weather;
}

