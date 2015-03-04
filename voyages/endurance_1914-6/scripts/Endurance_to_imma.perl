#!/usr/bin/perl

# Process digitised logbook data from the Endurance into
#  IMMA records.

use strict;
use warnings;
use MarineOb::IMMA;
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxeimb fwbpgv fxtftc fxtktc ix32dd ixdcdd fxbfms fwbptc);
use FindBin;
use Date::Calc qw(Add_Delta_Days);

my $Ship_name = 'Endurance';
my ( $Year, $Month, $Day );
my $Last_lon=51;
my $Last_lat=-3;
my $Lat_flag = 'N';
my $Lon_flag = 'W';

for ( my $i = 0 ; $i < 5 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Ob = new MarineOb::IMMA;
    $Ob->clear();                            # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $_;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
        $Year = $Fields[0];
    }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Month = $Fields[1];
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) {
        $Day = $Fields[2];
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        if($Fields[3]==2400) { 
	    ($Ob->{YR},$Ob->{MO},$Ob->{DY}) = Add_Delta_Days($Ob->{YR},$Ob->{MO},$Ob->{DY},1);
	    $Ob->{HR}=0;
        } else {
          $Ob->{HR} = int( $Fields[3] / 100 ) + ( $Fields[3] % 100 ) / 60;
        }
    }

    if ( defined( $Fields[4] ) && $Fields[4] =~ /[a-z]/ ) {    # Port name
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Fields[4] );
        $Ob->{LI} = 6;    # Position from metadata
    }
    else {
        if ( defined( $Fields[4] )
            && $Fields[4] =~ /(\d+)\D+(\d+)/ )
        {
            $Ob->{LAT} = $1 + $2 / 60;
        }
        elsif( defined( $Fields[5] )
            && $Fields[5] =~ /(\d+)\D+(\d+)/ )
        {
            $Ob->{LAT} = $1 + $2 / 60;
        }
        if ( defined($Fields[6]) && ( $Fields[6] eq 'N' || $Fields[6] eq 'S' ) ) {
                $Lat_flag = $Fields[6];
        }
        if ( defined( $Ob->{LAT}) && $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
        if ( defined( $Fields[4] )
            && $Fields[7] =~ /(\d+)\D+(\d+)/ )
        {
            $Ob->{LON} = $1 + $2 / 60;
        }
        elsif( defined( $Fields[8] )
            && $Fields[8] =~ /(\d+)\D+(\d+)/ )
        {
            $Ob->{LON} = $1 + $2 / 60;
        }
        if ( defined($Fields[9]) && ( $Fields[9] eq 'N' || $Fields[9] eq 'S' ) ) {
                $Lon_flag = $Fields[9];
        }
        if ( defined( $Ob->{LON}) && $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }

        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;    # Deg+Min position precision
        }
    }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }
    if ( defined( $Ob->{LAT} ) ) { $Last_lat = $Ob->{LAT}; }
    # Convert ob date and time to UTC
    if (   defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        my $elon = $Last_lon;
        if ( $elon < 0 ) { $elon += 360; }
        my ( $uhr, $udy ) = rxltut(
            $Ob->{HR} * 100,
            ixdtnd( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ),
            $elon * 100
        );
        $Ob->{HR} = $uhr / 100;
        ( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ) = rxnddt($udy);
    }
    else { $Ob->{HR} = undef; }

    # Pressure converted from inches
    if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ ) {
        if($Fields[12]<100) { $Ob->{SLP} = fxeimb($Fields[12]); } # inches Hg
        else { $Ob->{SLP} = $Fields[12]; } # hPa
    # Temperature correction
	if (   defined( $Ob->{SLP} )
	    && defined( $Fields[14] )
	    && $Fields[14] =~ /\d/ ) # F
	{
	    $Ob->{SLP} += fwbptc( $Ob->{SLP}, fxtftc( $Fields[14] ) );
	} elsif ( defined( $Ob->{SLP} )
	    && defined( $Fields[15] )
	    && $Fields[15] =~ /\d/ ) # K
    	{
	    $Ob->{SLP} += fwbptc( $Ob->{SLP}, fxtktc( $Fields[15] ) );
	}
	else { $Ob->{SLP} = undef; }
	# Gravity correction
	if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
	    $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
	}
    }
    # If no mercury pressure, use aneroid
    if(!defined($Ob->{SLP}) && defined( $Fields[13] ) && $Fields[13] =~ /\d/) {
        if($Fields[13]<100) { $Ob->{SLP} = fxeimb($Fields[13]); } # inches Hg
        else { $Ob->{SLP} = $Fields[13]; } # hPa
        unless($Ob->{YR}>1915 || 
           ($Ob->{YR}==1915 && $Ob->{MO}>10) ||
	       ($Ob->{YR}==1915 && $Ob->{MO}==10 && $Ob->{DY} >27)) {
           $Ob->{SLP} -= 10; # Fix - their aneroid is about 10hPa high. (On-ship only, not on the ice)
	}
    }   

    # Temperatures converted from Farenheit
    if ( defined( $Fields[16] ) && $Fields[16] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[16] );
    }
    if ( defined( $Fields[17] ) && $Fields[17] =~ /\d/ ) {
        $Ob->{WBT} = fxtftc( $Fields[17] );
    }
    if ( defined( $Fields[18] ) && $Fields[18] =~ /\d/ ) {
        $Ob->{SST} = fxtftc( $Fields[18] );
    }
    if ( !defined($Ob->{SST}) && defined($Fields[19] ) && $Fields[19] =~ /\d/ ) {
        $Ob->{SST} = fxtktc( $Fields[19] );
        if($Ob->{SST}< -5) { $Ob->{SST}=undef; } # Fix for some bad data in the spreadsheet
    }
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\S/ ) {
        my $Dirn = $Fields[10];
        $Dirn =~ s/b/x/;
        $Dirn =~ s/\//x/;
        $Dirn = sprintf "%-4s", uc($Dirn);
        if($Dirn =~ /CALM/) { $Ob->{D} = 361; }
        elsif($Dirn =~ /VAR/) { $Ob->{D} = 362; }
	else {
	    ( $Ob->{D}, undef ) = ix32dd($Dirn);
	    if ( defined( $Ob->{D} ) ) {
		$Ob->{DI} = 1;    # 32-point compass
	    }
	    else {
		warn "Unknown wind direction $Dirn - $Fields[8]";
	    }
	}
    }
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ ) {
                $Ob->{W}  = fxbfms($Fields[11]);    # Beaufort -> m/s
                $Ob->{WI} = 5;                 # Beaufort force
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;            
    $Ob->{ATTC} = 0;            # None
    $Ob->{TI}   = 0;            # Nearest hour time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = 3;            
    $Ob->{II}   = 10;           
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '03';         # UK recruited
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;          # Temps in degF and 10ths
    }

    $Ob->write( \*STDOUT );

	}

# Get a position from a port name
sub position_from_port {
    my $Name = lc(shift);
    if ( $Name =~ /santa cruz/ ) { # Tenerife
        return ( 28.5, -16.3 );   #
    }

    die "Unknown port $Name";
    #return ( undef, undef );
}

