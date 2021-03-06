#!/usr/bin/perl

# Process digitised logbook data from the Beagle into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'Beagle';
my ( $Year, $Month, $Day );
my $Last_lon;
my $Lat_flag = 'N';
my $Lon_flag = 'E';

for ( my $i = 0 ; $i < 8 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Ob = new IMMA;
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
        $Ob->{HR} = int( $Fields[3] / 100 ) + ( $Fields[3] % 100 ) / 60;
    }
    correct_hour_for_lon($Ob);

    if ( defined( $Fields[12] ) && $Fields[12] =~ /[a-z]/ ) {    # Port name
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Fields[12] );
        $Ob->{LI} = 6;    # Position from metadata
    }
    else {
        if ( defined( $Fields[12] )
            && $Fields[12] =~ /(\d+)\s+(\d+)\s*([NS]*)/ )
        {
            $Ob->{LAT} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'N' || $3 eq 'S' ) ) { $Lat_flag = $3; }
            if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
        }
        if ( defined( $Fields[13] )
            && $Fields[13] =~ /(\d+)\s+(\d+)\s*([EW]*)/ )
        {
            $Ob->{LON} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'E' || $3 eq 'W' ) ) { $Lon_flag = $3; }
            if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
        }
        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;    # Deg+Min position precision
        }
    }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }

    # Pressure converted from inches
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{SLP} = $Fields[8] * 33.86;
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ ) {
        $Ob->{AT} = ( $Fields[10] - 32 ) * 5 / 9;
    }
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ ) {
        $Ob->{SST} = ( $Fields[11] - 32 ) * 5 / 9;
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;            # Check with Scott
    $Ob->{ATTC} = 1;            # icoads
    $Ob->{TI}   = 0;            # Nearest hour time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = 3;            # Check with Scott
    $Ob->{II}   = 10;           # Check with Scott
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
    if ( $Name =~ /devonport|on board the beagle|barn pool|plymouth/ ) {
        return ( 50.37, -4.17 );
    }
    if ( $Name =~ /at sea|sailed/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /downs/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /abrolhos/ ) {
        return ( -17.96, -38.67 );
    }
    if ( $Name =~ /rio harbour|rio de janeiro/ ) {
        return ( -22.9, -43.13 );
    }
    if ( $Name =~ /atalaya church/ ) {
        return ( -34.94, -57.35 );
    }
    if ( $Name =~ /buenos ayres/ ) {
        return ( -34.59, -58.36 );
    }
    if ( $Name =~ /point indio/ ) {
        return ( -35.19, -57.02 );
    }
    if ( $Name =~ /blanco bay/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /hermoso/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /good success/ ) {
        return ( -54.78, -65.2 );
    }
    if ( $Name =~ /san martin cove/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /cape spencer/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /diego ramirez/ ) {
        return ( -56.6, -68.7 );
    }
    if ( $Name =~ /windhond bay/ ) {
        return ( -55.27, -67.88 );
    }
    if ( $Name =~ /goree road/ ) {
        return ( -55.29, -67.05 );
    }
    if ( $Name =~ /nassau bay/ ) {
        return ( -53.88, -71.07 );
    }
    if ( $Name =~ /packsaddle bay/ ) {
        return ( -55.4, -68.07 );
    }
    if ( $Name =~ /gretton bay/ ) {
        return ( -55.57, -67.5 );
    }
    if ( $Name =~ /oglander bay/ ) {
        return ( -55.15, -67.02 );
    }
    if ( $Name =~ /berkeley sound/ ) {
        return ( -51.58, -57.83 );
    }
    if ( $Name =~ /river negro/ ) {
        return ( -41.33, -62.75 );
    }
    if ( $Name =~ /maldonado/ ) {
        return ( -34.9, -54.95 );
    }
    if ( $Name =~ /san antonio/ ) {
        return ( -36.31, -56.75 );
    }
    if ( $Name =~ /sanborombon/ ) {
        return ( -35.67, -57.3 );
    }
    if ( $Name =~ /port desire/ ) {
        return ( -47.73, -65.82 );
    }
    if ( $Name =~ /st\.* julian/ ) {
        return ( -49.18, -67.62 );
    }
    if ( $Name =~ /possession bay/ ) {
        return ( -52.32, -69.33 );
    }
    if ( $Name =~ /first narrow|second narrow/ ) {    # Strait of Magellan
        return ( undef, undef );
    }
    if ( $Name =~ /gregory bay/ ) {
        return ( -52.65, -70.21 );
    }
    if ( $Name =~ /shoal harbour/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /cape negro/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /san sebastian/ ) {
        return ( -53.32, -68.16 );
    }
    if ( $Name =~ /cape san vicente/ ) {
        return ( -51.5, -74.0 );
    }
    if ( $Name =~ /san vicente bay/ ) {
        return ( -51.5, -74.0 );
    }
    if ( $Name =~ /strait le maire/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /wollaston island/ ) {
        return ( -55.59, -68.32 );
    }
    if ( $Name =~ /beagle channel/ ) {
        return ( -55.13, -66.57 );
    }
    if ( $Name =~ /woollya/ ) {
        return ( -55.6, -68.5 );
    }
    if ( $Name =~ /magdalen channel/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /cockburn channel/ ) {
        return ( undef, undef );
    }

    #        if ( $Name =~ /st. carlos|san *carlos/ ) {
    #        return ( -51.49, -59.04 );
    #    }
    if ( $Name =~ /st. carlos|san *carlos/ )
    {    # At least two places with this name
        return ( undef, undef );
    }
    if ( $Name =~ /chonos/ ) {
        return ( -45.9, -75.5 );
    }
    if ( $Name =~ /san pedro/ ) {
        return ( -43.35, -73.83 );
    }
    if ( $Name =~ /near the land/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /vallenar road/ ) {
        return ( -45.30, -74.6 );
    }
    if ( $Name =~ /san andres/ ) {    # Chonos archipelago
        return ( undef, undef );
    }
    if ( $Name =~ /christmas cove/ ) {
        return ( -46.58, -75.56 );
    }
    if ( $Name =~ /ynchemo island/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /patch cove/ ) {
        return ( -42.87, -74.92 );
    }
    if ( $Name =~ /lemu island/ ) {
        return ( -45.2, -74.57 );
    }
    if ( $Name =~ /port low/ ) {
        return ( -43.81, -74.05 );
    }
    if ( $Name =~ /huafo/ ) {
        return ( -43.7, -74.65 );
    }
    if ( $Name =~ /near the english bank/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /valdivia/ ) {
        return ( -39.88, -73.48 );
    }
    if ( $Name =~ /mocha/ ) {
        return ( -38.4, -73.95 );
    }
    if ( $Name =~ /concepcion/ ) {
        return ( -36.83, -73.08 );
    }
    if ( $Name =~ /st. mary|santa maria/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /tom. bay/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /coliumo/ ) {
        return ( -36.52, -73.02 );
    }
    if ( $Name =~ /horcon/ ) {
        return ( -32.69, -71.59 );
    }
    if ( $Name =~ /papudo/ ) {
        return ( -32.5, -71.51 );
    }
    if ( $Name =~ /pichidanque/ ) {
        return ( -32.13, -71.6 );
    }
    if ( $Name =~ /maytencillo/ ) {
        return ( -31.28, -71.1 );
    }
    if ( $Name =~ /lengua de vaca/ ) {
        return ( -30.22, -71.68 );
    }
    if ( $Name =~ /herradura/ ) {
        return ( -29.97, -71.43 );
    }
    if ( $Name =~ /copiap./ ) {
        return ( -27.33, -71.02 );
    }
    if ( $Name =~ /iquique/ ) {
        return ( -20.21, -70.24 );
    }
    if ( $Name =~ /callao/ ) {
        return ( -12.07, -77.23 );
    }
    if ( $Name =~ /barrington/ ) {
        return ( -0.84, -90.16 );
    }
    if ( $Name =~ /chatham island|stephens bay/ ) {
        return ( -0.83, -89.61 );
    }
    if ( $Name =~ /working round the island/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /charles island|post-office bay/ ) {
        return ( -1.31, -90.53 );
    }
    if ( $Name =~ /black beach/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /albemarle island/ ) {
        return ( -0.98, -91.53 );
    }
    if ( $Name =~ /s. w. extremity/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /elizabeth bay/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /banks bay/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /abingdon island/ ) {
        return ( 0.57, -90.8 );
    }
    if ( $Name =~ /towers.* island/ ) {
        return ( 0.33, -90.03 );
    }
    if ( $Name =~ /bindloes island/ ) {
        return ( 0.32, -90.57 );
    }
    if ( $Name =~ /james island/ ) {
        return ( 0.16, -90.85 );
    }
    if ( $Name =~ /hood island/ ) {
        return ( 1.42, -89.73 );
    }
    if ( $Name =~ /wenman islet/ ) {
        return ( 1.66, -92.07 );
    }
    if ( $Name =~ /matavai bay|papawa cove/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /bay of islands|new zealand/ ) {
        return ( -36.28, 174.16 );
    }
    if ( $Name =~ /three kings/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /van diemen/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /storm bay/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /hobart/ ) {
        return ( -42.89, 147.4 );
    }
    if ( $Name =~ /king george sound/ ) {
        return ( -35.03, 117.95 );
    }
    if ( $Name =~ /keeling island/ ) {
        return ( -12.08, 96.91 );
    }
    if ( $Name =~ /mauritius/ ) {
        return ( -20.16, 57.53 );
    }
    if ( $Name =~ /cape of good hope|simon bay/ ) {
        return ( -34.19, 18.43 );
    }
    if ( $Name =~ /st. helena/ ) {
        return ( -15.92, -5.71  );
    }
    if ( $Name =~ /pernambuco/ ) {
        return ( -8.06, -34.86  );
    }
    if ( $Name =~ /angra/ ) {
        return ( 38.76, -27.09  );
    }
    if ( $Name =~ /st. michaels/ ) {
        return ( 37.73, -25.67  );
    }
    if ( $Name =~ /falmouth/ ) {
        return ( 50.14, -5.05  );
    }
    if ( $Name =~ /thames/ ) {
        return ( undef, undef  );
    }
    if ( $Name =~ /greenwich/ ) {
        return ( 51.67, 0.0  );
    }
    if ( $Name =~ /woolwich/ ) {
        return ( 51.67, 0.0  );
    }

    if ( $Name =~ /sheerness/ ) {
        return ( 51.4, 0.8 );
    }
    if ( $Name =~ /dungeness/ ) {
        return ( 50.91, 0.98 );
    }
    if ( $Name =~ /beachy head/ ) {
        return ( 50.73, 0.25 );
    }
    if ( $Name =~ /downs/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /portsmouth/ ) {
        return ( 50.8, -1.1 );
    }
    if ( $Name =~ /spithead/ ) {
        return ( 50.8, -1.1, );
    }
    if ( $Name =~ /tagus/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /lisbon/ ) {
        return ( 38.7, -9.1 );
    }
    if ( $Name =~ /gibraltar/ ) {
        return ( 36.1, -5.3 );
    }
    if ( $Name =~ /madeira/ ) {
        return ( 32.6, -16.9 );    # Funchal bay
    }
    if ( $Name =~ /tenerife/ ) {
        return ( 28.5, -16.25 );    # Santa Cruz
    }
#    if ( $Name =~ /santa cruz/ ) {
#        return ( 28.5, -16.25 );
#    }
    if ( $Name =~ /santa cruz/ ) { # Rio Santa Cruz, patagonia
        return ( -50.1, -68.3 );   # Guessed
    }
    if ( $Name =~ /st thomas/ ) {
        return ( 18.33, -64.98 );
    }
    if ( $Name =~ /bermuda/ ) {
        return ( 32.3, -64.8 );
    }
    if ( $Name =~ /halifax/ ) {
        return ( 44.6, -63.6 );
    }
    if ( $Name =~ /fayal/ ) {
        return ( 38.55, -28.77 );
    }
    if ( $Name =~ /delgada/ ) {
        return ( 37.73, -25.66 );
    }
    if ( $Name =~ /funchal/ ) {
        return ( 32.6, -16.9 );
    }
    if ( $Name =~ /st vincent/ ) {
        return ( 16.8, -25.0 );
    }
    if ( $Name =~ /porto grande/ ) {
        return ( 16.8, -25.0 );
    }
    if ( $Name =~ /porto* praya/ ) {
        return ( 14.9, -23.5 );
    }
    if ( $Name =~ /st paul's rocks/ ) {
        return ( 0.92, -29.37 );
    }
    if ( $Name =~ /san antonio bay/ ) {    # On Fernando Noronha
        return ( -3.85, -32.42 );
    }
    if ( $Name =~ /fernando noronha/ ) {
        return ( -3.85, -32.42 );
    }
    if ( $Name =~ /bahia/ ) {
        return ( -12.98, -38.51 );
    }
    if ( $Name =~ /tristan|inaccessible|nightingale/ ) {
        return ( -37.1, -12.3 );
    }
    if ( $Name =~ /simon's bay/ ) {
        return ( -34.2, 18.4 );
    }
    if ( $Name =~ /table bay/ ) {
        return ( -33.9, 18.4 );
    }
    if ( $Name =~ /kerguelen|bets[yt]|royal sound|island harbour/ ) {
        return ( -49.34, 70.2 );
    }
    if ( $Name =~ /greenland harbour|cascade beach|hopeful harbour/ ) {
        return ( -49.34, 70.2 );    # more Kerguelen
    }
    if (
        $Name =~ /fuller's harbour|christmas harbour|prince of wales foreland/ )
    {
        return ( -49.34, 70.2 );    # still more Kerguelen
    }
    if ( $Name =~ /heard island|corinthian bay/ ) {
        return ( -53.1, 73.7 );
    }
    if ( $Name =~ /melbourne|hobson|phillip/ ) {
        return ( -37.8, 145.0 );
    }
    if ( $Name =~ /sydney|jackson|farm cove|watson/ ) {
        return ( -33.9, 151.2 );
    }
    if ( $Name =~ /hardy/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /queen charlotte|ship cove/ ) {
        return ( -41.18, 174.19 );
    }
    if ( $Name =~ /nicholson/ ) {
        return ( -41.3, 174.83 );
    }
    if ( $Name =~ /wellington/ ) {
        return ( -41.3, 174.8 );
    }
    if ( $Name =~ /tongatabu/ ) {
        return ( -21.17, -175.17 );
    }
    if ( $Name =~ /ngaola|ngaloa/ ) {
        return ( -19.08, 178.18 );
    }
    if ( $Name =~ /levuka/ ) {
        return ( -18.13, 178.57 );
    }
    if ( $Name =~ /api island/ ) {    # Vanautu?
        return ( undef, undef );
    }
    if ( $Name =~ /raine island/ ) {
        return ( -11.6, 144.3 );
    }
    if ( $Name =~ /albany/ ) {
        return ( -10.73, 142.58 );
    }
    if ( $Name =~ /hammond/ ) {
        return ( -10.55, 142.18 );
    }
    if ( $Name =~ /dobbo/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /ki doulan/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /banda harbour/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /amboina/ ) {
        return ( -3.71, 128.2 );
    }
    if ( $Name =~ /ternate/ ) {
        return ( 0.77, 127.39 );
    }

    #    if ( $Name =~ /samboangan/ ) {
    #        return ( 9.88, 123.87 );
    #    }
    if ( $Name =~ /samboangan/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /ilo ilo/ ) {
        return ( 11.0, 122.67 );
    }
    if ( $Name =~ /manila/ ) {
        return ( 14.5, 120.8 );
    }
    if ( $Name =~ /hong kong/ ) {
        return ( 22.3, 114.2 );
    }
    if ( $Name =~ /zebu/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /malanipa/ ) {
        return ( 6.88, 122.27 );
    }
    if ( $Name =~ /port isabella/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /humboldt bay/ ) {
        return ( -2.58, 140.75 );
    }
    if ( $Name =~ /nares harbour/ ) {    # Made-up. NW of Manus Island
        return ( -1.95, 147.18 );
    }
    if ( $Name =~ /yokohama/ ) {
        return ( 35.5, 139.7 );
    }
    if ( $Name =~ /yoi*koska/ ) {
        return ( 35.27, 139.67 );
    }
    if ( $Name =~ /kaneda/ ) {
        return ( 35.17, );
    }
    if ( $Name =~ /oosima/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /kobe/ ) {
        return ( 34.7, 135.1 );
    }
    if ( $Name =~ /sakate/ ) {
        return ( 34.45, 134.32 );
    }
    if ( $Name =~ /miwara/ ) {
        return ( 34.4, 132.83 );
    }
    if ( $Name =~ /honolulu/ ) {
        return ( 21.3, -157.9 );
    }
    if ( $Name =~ /hilo/ ) {
        return ( 19.72, -155.08 );
    }
    if ( $Name =~ /papiete|tahiti/ ) {
        return ( -17.52, -149.56 );
    }
    if ( $Name =~ /cumberland bay/ ) {
        return ( -33.62, -78.82 );
    }
    if ( $Name =~ /valparaiso/ ) {
        return ( -33.0, -71.6 );
    }
    if ( $Name =~ /hale cove/ ) {
        return ( -47.93, -74.62 );    # Orlebar Island
    }
    if ( $Name =~ /gr[ea]y harbour/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /port grappler/ ) {
        return ( -49.42, -74.32 );
    }
    if ( $Name =~ /tom bay/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /pu[oe]rto bueno/ ) {
        return ( -50.98, -74.22 );
    }
    if ( $Name =~ /isthmus harbour/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /port churruca/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /port famine/ ) {
        return ( -53.63, -70.93 );
    }
    if ( $Name =~ /sandy point/ ) {    # Punta Arenas
        return ( -53.1, -70.9 );
    }
    if ( $Name =~ /elizabeth island/ ) {    # Isla Isabel
        return ( -52.88, -70.70 );          # Doubtful, several possibilities
    }
    if ( $Name =~ /port stanley/ ) {
        return ( -51.7, -57.9 );
    }
#    if ( $Name =~ /port louis/ ) {
#        return ( -51.55, -58.13 );
#    }
    if ( $Name =~ /port louis/ ) { # Also at mauritius
        return ( undef, undef );
    }
    if ( $Name =~ /monte video/ ) {
        return ( -34.9, -56.2 );
    }
    if ( $Name =~ /ascension/ ) {
        return ( -8.0, -14.4 );
    }
    if ( $Name =~ /vigo/ ) {
        return ( 43.57, -6.63 );
    }

    die "Unknown port $Name";
    #return ( undef, undef );
}

# Correct the date to UTC from local time
# This version not used here - kept in for historical reasons.
sub correct_hour_for_lon {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob = shift;
    unless ( defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        $Ob->{HR} = undef;
        return;
    }
    if ( $Ob->{YR} % 4 == 0
        && ( $Ob->{YR} % 100 != 0 || $Ob->{YR} % 400 == 0 ) )
    {
        $Days_in_month[1] = 29;
    }
    $Ob->{HR} += $Last_lon * 12 / 180;
    if ( $Ob->{HR} < 0 ) {
        $Ob->{HR} += 24;
        $Ob->{DY}--;
        if ( $Ob->{DY} <= 0 ) {
            $Ob->{MO}--;
            if ( $Ob->{MO} < 1 ) {
                $Ob->{YR}--;
                $Ob->{MO} = 12;
            }
            $Ob->{DY} = $Days_in_month[ $Ob->{MO} - 1 ];
        }
    }
    if ( $Ob->{HR} > 23.99 ) {
        $Ob->{HR} -= 24;
        if ( $Ob->{HR} < 0 ) { $Ob->{HR} = 0; }
        $Ob->{DY}++;
        if ( $Ob->{DY} > $Days_in_month[ $Ob->{MO} - 1 ] ) {
            $Ob->{DY} = 1;
            $Ob->{MO}++;
            if ( $Ob->{MO} > 12 ) {
                $Ob->{YR}++;
                $Ob->{MO} = 1;
            }
        }
    }
    if ( $Ob->{HR} == 23.99 ) { $Ob->{HR} = 23.98; }
    return 1;
}
