#!/usr/bin/perl -w
use strict;
use warnings;
use CGI;
use DBI;
use JSON;

my $database = "/home/www/data/spor.db";
my $cgi;

sub parm{ # wash script attack away
    my $parm=shift;
    $parm =~ s/\:\$\?\|\\/_/g;
    return $cgi->param("$parm"); 
}

sub pakk{
    my $parm=shift;
    # return '"' . parm($parm) . '"';
    return parm($parm); # apastrophes comes in httprequest
}

# read the CGI params
$cgi = CGI->new;
my $username = parm("username");
# my $password = parm("password");

# connect to the database
my $driver   = "SQLite";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
    or die $DBI::errstr;
my %result=();

my $oper=parm("oper") || 'ukjent';
if ( $oper eq "reg" ){
    my $insert= sprintf( "insert into spor values ( %s, %s, %s, %s, %s, %s, %s );",
			 pakk('gruppe'), pakk('navn'), pakk('lat'), pakk('lon'), pakk('dir'), pakk('speed'),pakk('time') );
    print STDERR $insert if parm("debug");
    if ($dbh->do($insert)){
        $result{status}="OK";
    } else {
        $result{status}="ERROR";
        $result{'code'} = $DBI::errstr;
    }

} elsif ( $oper eq "spor" ){

    # check the username and password in the database

    my $statement = 'SELECT navn, lat, lon, time FROM spor where gruppe = "' . parm('gruppe') . '";';
    print STDERR $statement if parm("debug");
    my $sth = $dbh->prepare($statement);
    if ( ! $sth ){
	$result{status}="ERROR";
	$result{'code'} = $dbh->errstr;
#    } elsif( ! $sth->execute($userid, $password) ){
    } elsif( ! $sth->execute() ){
	$result{status}="ERROR";
	$result{'code'} = $sth->errstr;
    } else { # result ok
	$result{status} = "OK";
	@{$result{spor}} = ();
	while(my @row = $sth->fetchrow_array()) {
	    push( @{$result{spor}}, {
		'navn' => $row[0],
		    'lat' => $row[1],
		    'lon' => $row[2],
		    'time' => $row[3]
		  } );
	}
    }

} elsif ( $oper eq "list"){
	
} else {
    	$result{status}="ERROR";
	$result{'code'} = "Gyldige kommandoer : reg og spor";
}
    
# return JSON string
print $cgi->header(-type => "application/json", -charset => "utf-8");
print encode_json(\%result) . "\n";

exit(0)
