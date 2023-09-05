#!/usr/bin/perl

use DBI;
use strict;
use warnings;
use YAML::Tiny;

my $yaml = "config.yaml";
my $yamlobj = YAML::Tiny->read($yaml);
my $driver = "Pg";
my $database = $yamlobj->[0]->{database};
my $host = $yamlobj->[0]->{host};
my $port = $yamlobj->[0]->{port};
my $dsn = "DBI:$driver:dbname = $database;host = $host;port = $port";
my $userid = $yamlobj->[0]->{userid};
my $password = $yamlobj->[0]->{password};
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
print "Opened database successfully\n";

my $stmt = qq(create table known_words
(
    entry      text not null
        constraint known_words_pk
            unique,
    definition text not null
) tablespace hexojp;);
my $rv = $dbh->do($stmt);

if($rv < 0) {
  print $DBI::errstr;
} else {
  print "Table created successfully.\n";
}

$dbh->disconnect();
print "Disconnected from database.\n";