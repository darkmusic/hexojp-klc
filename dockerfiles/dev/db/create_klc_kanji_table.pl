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

my $stmt = qq(create table klc_kanji
(
    id       serial,
    klc_number integer not null,
    character_id integer not null
        constraint klc_kanji_character_id_fk
            references character
) tablespace hexojp;);
my $rv = $dbh->do($stmt);

if($rv < 0) {
  print $DBI::errstr;
} else {
  print "Table created successfully.\n";

  $stmt = qq(create unique index klc_kanji_character_id_uindex
      on klc_kanji (character_id););
  $rv = $dbh->do($stmt);

  if($rv < 0) {
    print $DBI::errstr;
  } else {
    print "Index created successfully.\n";
  }
}

$dbh->disconnect();
print "Disconnected from database.\n";