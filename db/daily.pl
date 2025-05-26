#!/usr/bin/perl

use DBI;
use DBD::Pg qw(:pg_types);
use strict;
use warnings;
use YAML::Tiny;
use utf8;
use POSIX qw(strftime);
use List::Util qw(shuffle);

my $yaml = "config.yaml";
my $yamlobj = YAML::Tiny->read($yaml);
my $driver = "Pg";
my $database = $yamlobj->[0]->{database};
my $host = $yamlobj->[0]->{host};
my $port = $yamlobj->[0]->{port};
my $dsn = "DBI:$driver:dbname = $database;host = $host;port = $port";
my $userid = $yamlobj->[0]->{userid};
my $password = $yamlobj->[0]->{password};
my $last_known_klc_num = $yamlobj->[0]->{last_known_klc_num};
my $daily_study_number = $yamlobj->[0]->{daily_study_number};
my $max_words = $yamlobj->[0]->{max_words};
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;
my $note_name = strftime "%m-%d-%Y", localtime;
print "Opened database successfully\n";

# Calculate min and max number
my $daily_min = $last_known_klc_num + 1;
my $daily_max = $last_known_klc_num + $daily_study_number;

# Update last known kanji num
$yamlobj->[0]->{last_known_klc_num} = $daily_max;

# These other numeric values are being converted to strings on write, so force them to be numeric
$yamlobj->[0]->{daily_study_number} = $daily_study_number + 0;
$yamlobj->[0]->{max_words} = $max_words + 0;
$yamlobj->[0]->{port} = $port + 0;
$yamlobj->write($yaml);

# Add matching words
my $sql = qq(do \$\$
    begin
        call add_matching_words($daily_max);
    end;
\$\$;);
my $rv = $dbh->do($sql);

# Get kanji basic info
my $output = "";
$sql = qq(
  select c.id, c.literal 
    from character c, klc_kanji kk 
    where kk.character_id = c.id 
    and kk.klc_number between ? and ?;);
#print("$sql\n");
my $kanji_sth = $dbh->prepare($sql);
#print "daily min: $daily_min, daily max: $daily_max\n";
$kanji_sth->execute($daily_min, $daily_max);
while (my @kanjiRow = $kanji_sth->fetchrow_array) {
  $output = $output . "## $kanjiRow[1]\n";

  # Now get meanings
  my $has_meaning = 0;
  my $meaning_text = "";
  $sql = qq(select meaning from meaning where character = ? and language = 'en';);
  #print("$sql\n");
  my $reading_sth = $dbh->prepare($sql);
  $reading_sth->execute($kanjiRow[0]);
  while (my @meaningRow = $reading_sth->fetchrow_array) {
    $has_meaning = 1;
    $meaning_text = $meaning_text . "- $meaningRow[0]\n"
  }
  if ($has_meaning == 1) {
      $output = $output . "**Meanings:**\n";
      $output = $output . $meaning_text . "\n";
  }

  # Now get on readings
  my $has_onreading = 0;
  my $onreading_text = "";
  $sql = qq(select reading from reading where character = ? and type = 'ja_on';);
  #print("$sql\n");
  $reading_sth = $dbh->prepare($sql);
  $reading_sth->execute($kanjiRow[0]);
  while (my @onReadingRow = $reading_sth->fetchrow_array) {
    $has_onreading = 1;
    $onreading_text = $onreading_text . "- $onReadingRow[0]\n"
  }
  if ($has_onreading == 1) {
      $output = $output . "**On Readings:**\n";
      $output = $output . $onreading_text . "\n";
  }

  # Now get kun readings
  my $has_kunreading = 0;
  my $kunreading_text = "";
  $sql = qq(select reading from reading where character = ? and type = 'ja_kun';);
  #print("$sql\n");
  $reading_sth = $dbh->prepare($sql);
  $reading_sth->execute($kanjiRow[0]);
  while (my @kunReadingRow = $reading_sth->fetchrow_array) {
    $has_kunreading = 1;
    $kunreading_text = $kunreading_text . "- $kunReadingRow[0]\n"
  }
  if ($has_kunreading == 1) {
      $output = $output . "**Kun Readings:**\n";
      $output = $output . $kunreading_text . "\n";
  }
}

# Now get sample words for all known kanji
my $current_word = 1;
my $has_word = 0;
my $word_text = "";
$sql = qq(select kw.entry, kw.definition from known_words kw;);
#print("$sql\n");
my $word_sth = $dbh->prepare($sql);
$word_sth->execute();
my $all_matching_words = $word_sth->fetchall_arrayref;
@$all_matching_words = shuffle(@$all_matching_words);
for my $row ( @$all_matching_words ) {
  my @wordRow = @$row;
  $has_word = 1;
  $word_text = $word_text . "- $wordRow[0] : $wordRow[1]\n";
  if($current_word == $max_words) {
    last;
  }
  $current_word = $current_word + 1;
}

if($has_word == 1) {
  $output = $output . "**Words:**\n$word_text\n";
}

$dbh->disconnect();
print "Disconnected from database.\n";

# Generate hexo post
print "Generating hexo post.\n";
my $hexo_output = `hexo new post $note_name`;
print "$hexo_output\n";

# Append generated output to post
my $filename = "../source/_posts/$note_name.md";
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
say $fh $output;
close $fh;
