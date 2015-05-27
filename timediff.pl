# timediff.pl           Time-stamp: Fri Oct 10 2003 

while()
{
    print "\nEnter end   time [hh:mm:ss] : ";

    ($hr, $min, $sec) = split(/:/, <STDIN>);

    $endTotal = ($hr * 3600) + ($min * 60) + $sec;

    last if ($endTotal == 0);

#print "\nEnd total seconds: $endTotal\n\n";

    print "Enter start time [hh:mm:ss] : ";

    ($hr, $min, $sec) = split(/:/, <STDIN>);

    $startTotal = ($hr * 3600) + ($min * 60) + $sec;

#print "\nStart total seconds: $startTotal\n";

    $diff  = $endTotal - $startTotal;

#printf "\nDifferance seconds = %ld\n\n", $diff;

    $hr  = $diff / 3600;

    $min = ($diff % 3600) / 60;

    $sec = ($diff % 60);

    printf("\nDifferance = %02ld:%02ld:%02ld\n", $hr, $min, $sec);
}
