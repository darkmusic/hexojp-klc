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

my $stmt = qq(create or replace procedure add_matching_words(max_klc integer)
language plpgsql
as \$\$
    declare agg_kanji text;
    begin
        truncate table known_words;
        select string_agg(c.literal, '') into agg_kanji
                                         from klc_kanji kk, character c
                                         where kk.character_id = c.id and kk.klc_number <= max_klc;
        insert into known_words(entry, definition)
            select entry, definition from word w where regexp_count(entry, '^([ぁ-んァ-ン' || agg_kanji || ']+) \\[(.+)\\]\\x20\$') > 0;
    end;
\$\$;);
my $rv = $dbh->do($stmt);

if($rv < 0) {
  print $DBI::errstr;
} else {
  print "Procedure created successfully.\n";
}

$dbh->disconnect();
print "Disconnected from database.\n";