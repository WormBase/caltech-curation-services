#!/usr/bin/perl -w

# pic_name -> id of picture, picture name
# pic_user -> id of user, name of user
# pic_category -> id of category, name of category
# pic_value -> id of picture, id of user, id of category, value of category for picture and user
# pic_type -> id of picture, picture type (jpg / mpeg / &c.)
# pic_comment -> id of picture, comment
# pic_text -> id of picture, text of sign / what not

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# &recreateTables();

# &populateJapan();


sub populateJapan {
  my @command_queue;
  my @directories = qw ( 20071117-Kyoto/ 20071118-Kyoto/ 20071119-Kyoto/ 20071120-Kyoto/ 20071121-Kyoto/ 20071122-Nara/ 20071123-Osaka/ 20071124-Naoshima/ 20071124-TonoFotos/ 20071125-TakamatsuRitsurinPark/ 20071125-Yashima/ 20071126-Kurashiki/ 20071128-Miyajima/ 20071128-TonoPictures/ 20071129-Koyasan/ 20071130-Koyasan/ 20071201-Koyasan/ 20071202-Takayama/ 20071203-Takayama/ 20071204-Shirakawa/ 20071205-Shirakawa/ 20071206-Takayama/ 20071207-Hakone/ 20071208-Hakone/ 20071209-Tokyo/ 20071210-Tokyo/ 20071211-Kamakura/ 20071212-Tokyo/ 20071213-Tokyo/ 20071214-Shinjuku/ 20071215-Harajuku/ 20071216-AkabusaRoppongi/ 20071217-RoppongiShinjuku/ 20071218-RoppongiShinjuku/ 20071219-TokyoLA/ 20071224-XmasStuff/ );
  foreach my $directory (@directories) { 
    my @pictures = </home2/azurebrd/public_html/pics/${directory}2007*>;
    foreach my $picture (@pictures) {
      my $ext = 'jpg';
      if ($picture =~ m/jpg$/) { $ext = 'jpg'; }
      elsif ($picture =~ m/avi$/) { $ext = 'avi'; }
      elsif ($picture =~ m/mov$/) { $ext = 'mov'; }
      else { die "ERR $picture extension is neither avi nor jpg\n"; } } } 
  foreach my $directory (@directories) { 
    my @pictures = </home2/azurebrd/public_html/pics/${directory}2007*>;
    foreach my $picture (@pictures) {
      my $ext = 'jpg';
      if ($picture =~ m/jpg$/) { $ext = 'jpg'; }
      elsif ($picture =~ m/avi$/) { $ext = 'avi'; }
      elsif ($picture =~ m/mov$/) { $ext = 'mov'; }
      else { die "ERR $picture extension is neither avi nor jpg\n"; }
      my ($picID) = &getNewPicID();
      my $command = "INSERT INTO pic_name VALUES ('$picID', '$picture');";
      print "$command\n";
      my $result = $conn->exec( $command );
      $command = "INSERT INTO pic_name_sdw VALUES ('$picID', '$picture');";
      print "$command\n";
      $result = $conn->exec( $command );
      $command = "INSERT INTO pic_type VALUES ('$picID', '$ext');";
      print "$command\n";
      $result = $conn->exec( $command );
      $command = "INSERT INTO pic_type_sdw VALUES ('$picID', '$ext');";
      print "$command\n";
      $result = $conn->exec( $command );
      $command = "INSERT INTO pic_value VALUES ('$picID', '1', '13', '5');";
      print "$command\n";
      $result = $conn->exec( $command ); 
      $command = "INSERT INTO pic_value_sdw VALUES ('$picID', '1', '13', '5');";
      print "$command\n";
      $result = $conn->exec( $command ); }
  } # foreach my $directory (@directories)

} # sub populateJapan

sub getNewPicID {
  my $pic = 0;
  my $result = $conn->exec( "SELECT joinkey FROM pic_name ORDER BY joinkey DESC;" );
  my @row = $result->fetchrow();
  if ($row[0]) { $pic = $row[0]; }
  $pic++; 
  return $pic;
} # sub getNewPicID

sub recreateTables {
  my @types = qw( not sdw );
  my @tables = qw( user category name type comment text );
  foreach my $table (@tables) {
    $table = 'pic_' . $table;
    foreach my $type (@types) {
      my $column_head = $table;
      if ($type eq 'sdw') { $table .= "_sdw"; }
      my $result = $conn->exec( "DROP TABLE $table ;" );
      if ( ($table =~ m/comment/) || ($table =~ m/text/) ) {
        print "CREATE TABLE $table ( joinkey integer, pic_user integer, $column_head text, pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );\n"; 
        $result = $conn->exec( "CREATE TABLE $table (
          joinkey integer,
          pic_user integer,
          $column_head text,
          pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) ); " ); 
      } else {
        print "CREATE TABLE $table ( joinkey integer, $column_head text, pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );\n"; 
        $result = $conn->exec( "CREATE TABLE $table (
          joinkey integer,
          $column_head text,
          pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) ); " ); }
      $result = $conn->exec( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
      $result = $conn->exec( "REVOKE ALL ON TABLE $table FROM postgres; ");
      $result = $conn->exec( "GRANT ALL ON TABLE $table TO postgres; ");
      $result = $conn->exec( "GRANT SELECT ON TABLE $table TO acedb; ");
      $result = $conn->exec( "GRANT ALL ON TABLE $table TO apache; ");
      $result = $conn->exec( "GRANT ALL ON TABLE $table TO cecilia; ");
      $result = $conn->exec( "GRANT ALL ON TABLE $table TO azurebrd; ");
      $result = $conn->exec( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey); ");
    } # foreach my $type (@types)
  } # foreach my $table (@tables)

  foreach my $type (@types) {
    my $table = 'pic_value';
    my $column_head = $table;
    if ($type eq 'sdw') { $table .= "_sdw"; }
    my $result = $conn->exec( "DROP TABLE $table ;" );
    $result = $conn->exec( "CREATE TABLE $table (
      joinkey integer,
      pic_user integer,
      pic_category integer,
      pic_value integer,
      pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
    $result = $conn->exec( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
    $result = $conn->exec( "REVOKE ALL ON TABLE $table FROM postgres; ");
    $result = $conn->exec( "GRANT ALL ON TABLE $table TO postgres; ");
    $result = $conn->exec( "GRANT SELECT ON TABLE $table TO acedb; ");
    $result = $conn->exec( "GRANT ALL ON TABLE $table TO apache; ");
    $result = $conn->exec( "GRANT ALL ON TABLE $table TO cecilia; ");
    $result = $conn->exec( "GRANT ALL ON TABLE $table TO azurebrd; ");
    $result = $conn->exec( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey); ");
  } # foreach my $type (@types)

  my $result = $conn->exec( "INSERT INTO pic_category VALUES ('1', 'Good Picture'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('1', 'Good Picture'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('2', 'Not Blurry'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('2', 'Not Blurry'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('3', 'Deeya'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('3', 'Deeya'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('4', 'Juancarlos'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('4', 'Juancarlos'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('5', 'Funny'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('5', 'Funny'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('6', 'Cute'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('6', 'Cute'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('7', 'Mrowr'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('7', 'Mrowr'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('8', 'Rory'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('8', 'Rory'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('9', 'Ceci'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('9', 'Ceci'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('10', 'Juank'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('10', 'Juank'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('11', 'Ken'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('11', 'Ken'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('12', 'Pasadena'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('12', 'Pasadena'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('13', 'Japan'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('13', 'Japan'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('14', 'Sign'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('14', 'Sign'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('15', 'Cat'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('15', 'Cat'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('16', 'Pole'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('16', 'Pole'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('17', 'Kimono'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('17', 'Kimono'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('18', 'Airport'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('18', 'Airport'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('19', 'Train'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('19', 'Train'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('20', 'Plane'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('20', 'Plane'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('21', 'View'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('21', 'View'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('22', 'Camera'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('22', 'Camera'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('23', 'Meal'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('23', 'Meal'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('24', 'Ryokan'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('24', 'Ryokan'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('25', 'Shrine'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('25', 'Shrine'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('26', 'Temple'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('26', 'Temple'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('27', 'Yoga'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('27', 'Yoga'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('28', 'Car'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('28', 'Car'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('29', 'Foliage'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('29', 'Foliage'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('30', 'Water'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('30', 'Water'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('31', 'Torii'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('31', 'Torii'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('32', 'Playground'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('32', 'Playground'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('33', 'Street'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('33', 'Street'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('34', 'Restaurant'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('34', 'Restaurant'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('35', 'Vending Machine'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('35', 'Vending Machine'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('36', 'Deeya Shot'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('36', 'Deeya Shot'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('37', 'Bus'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('37', 'Bus'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('38', 'Castle'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('38', 'Castle'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('39', 'Gate'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('39', 'Gate'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('40', 'Map'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('40', 'Map'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('41', 'Fish'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('41', 'Fish'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('42', 'Swan'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('42', 'Swan'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('43', 'Buddha'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('43', 'Buddha'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('44', 'Bird'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('44', 'Bird'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('45', 'Sand'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('45', 'Sand'); ");
  $result = $conn->exec( "INSERT INTO pic_category VALUES ('46', 'Hotel'); ");
  $result = $conn->exec( "INSERT INTO pic_category_sdw VALUES ('46', 'Hotel'); ");
  $result = $conn->exec( "INSERT INTO pic_user VALUES ('1', 'Juancarlos'); ");

} # sub recreateTables

__END__

# For a restraint on 3 columns
#     $table = 'pic_value_sdw';
#     $column_head = 'pic_value';
#     $result = $conn->exec( "DROP TABLE $table ;" );
#     $result = $conn->exec( "CREATE TABLE $table (
#       pic_name integer,
#       pic_users integer,
#       pic_category integer,
#       pic_value integer,
#       UNIQUE (pic_name, pic_users, pic_category), 
#       pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
#     $result = $conn->exec( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
#     $result = $conn->exec( "REVOKE ALL ON TABLE $table FROM postgres; ");
#     $result = $conn->exec( "GRANT ALL ON TABLE $table TO postgres; ");
#     $result = $conn->exec( "GRANT SELECT ON TABLE $table TO acedb; ");
#     $result = $conn->exec( "GRANT ALL ON TABLE $table TO apache; ");
#     $result = $conn->exec( "GRANT ALL ON TABLE $table TO cecilia; ");
#     $result = $conn->exec( "GRANT ALL ON TABLE $table TO azurebrd; ");
#     $result = $conn->exec( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey); ");
# 
# print "start\n";
#   my $result = $conn->exec( "
# DROP TABLE pic_users;
# DROP TABLE pic_category;
# DROP TABLE pic_name;
# DROP TABLE pic_type;
# DROP TABLE pic_value;
# 
# CREATE TABLE pic_users (
#     joinkey integer,
#     pic_users text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_users FROM PUBLIC;
# REVOKE ALL ON TABLE pic_users FROM postgres;
# GRANT ALL ON TABLE pic_users TO postgres;
# GRANT SELECT ON TABLE pic_users TO acedb;
# GRANT ALL ON TABLE pic_users TO apache;
# GRANT ALL ON TABLE pic_users TO cecilia;
# GRANT ALL ON TABLE pic_users TO azurebrd;
# CREATE INDEX pic_users_idx ON pic_users USING btree (joinkey);
# CREATE TABLE pic_users_sdw (
#     joinkey integer,
#     pic_users text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_users_sdw FROM PUBLIC;
# REVOKE ALL ON TABLE pic_users_sdw FROM postgres;
# GRANT ALL ON TABLE pic_users_sdw TO postgres;
# GRANT SELECT ON TABLE pic_users_sdw TO acedb;
# GRANT ALL ON TABLE pic_users_sdw TO apache;
# GRANT ALL ON TABLE pic_users_sdw TO cecilia;
# GRANT ALL ON TABLE pic_users_sdw TO azurebrd;
# CREATE INDEX pic_users_sdw_idx ON pic_users_sdw USING btree (joinkey);
# 
# CREATE TABLE pic_category (
#     joinkey integer,
#     pic_category text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_category FROM PUBLIC;
# REVOKE ALL ON TABLE pic_category FROM postgres;
# GRANT ALL ON TABLE pic_category TO postgres;
# GRANT SELECT ON TABLE pic_category TO acedb;
# GRANT ALL ON TABLE pic_category TO apache;
# GRANT ALL ON TABLE pic_category TO cecilia;
# GRANT ALL ON TABLE pic_category TO azurebrd;
# CREATE INDEX pic_category_idx ON pic_category USING btree (joinkey);
# CREATE TABLE pic_category_sdw (
#     joinkey integer,
#     pic_category text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_category_sdw FROM PUBLIC;
# REVOKE ALL ON TABLE pic_category_sdw FROM postgres;
# GRANT ALL ON TABLE pic_category_sdw TO postgres;
# GRANT SELECT ON TABLE pic_category_sdw TO acedb;
# GRANT ALL ON TABLE pic_category_sdw TO apache;
# GRANT ALL ON TABLE pic_category_sdw TO cecilia;
# GRANT ALL ON TABLE pic_category_sdw TO azurebrd;
# CREATE INDEX pic_category_sdw_idx ON pic_category_sdw USING btree (joinkey);
# 
# 
# CREATE TABLE pic_name (
#     joinkey integer,
#     pic_name text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_name FROM PUBLIC;
# REVOKE ALL ON TABLE pic_name FROM postgres;
# GRANT ALL ON TABLE pic_name TO postgres;
# GRANT SELECT ON TABLE pic_name TO acedb;
# GRANT ALL ON TABLE pic_name TO apache;
# GRANT ALL ON TABLE pic_name TO cecilia;
# GRANT ALL ON TABLE pic_name TO azurebrd;
# CREATE INDEX pic_name_idx ON pic_name USING btree (joinkey);
# CREATE TABLE pic_name_sdw (
#     joinkey integer,
#     pic_name text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_name_sdw FROM PUBLIC;
# REVOKE ALL ON TABLE pic_name_sdw FROM postgres;
# GRANT ALL ON TABLE pic_name_sdw TO postgres;
# GRANT SELECT ON TABLE pic_name_sdw TO acedb;
# GRANT ALL ON TABLE pic_name_sdw TO apache;
# GRANT ALL ON TABLE pic_name_sdw TO cecilia;
# GRANT ALL ON TABLE pic_name_sdw TO azurebrd;
# CREATE INDEX pic_name_sdw_idx ON pic_name_sdw USING btree (joinkey);
# 
# CREATE TABLE pic_type (
#     joinkey integer,
#     pic_type text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_type FROM PUBLIC;
# REVOKE ALL ON TABLE pic_type FROM postgres;
# GRANT ALL ON TABLE pic_type TO postgres;
# GRANT SELECT ON TABLE pic_type TO acedb;
# GRANT ALL ON TABLE pic_type TO apache;
# GRANT ALL ON TABLE pic_type TO cecilia;
# GRANT ALL ON TABLE pic_type TO azurebrd;
# CREATE INDEX pic_type_idx ON pic_typtypeING btree (joinkey);
# CREATE TABLE pic_type_sdw (
#     joinkey integer,
#     pic_type text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_type_sdw FROM PUBLIC;
# REVOKE ALL ON TABLE pic_type_sdw FROM postgres;
# GRANT ALL ON TABLE pic_type_sdw TO postgres;
# GRANT SELECT ON TABLE pic_type_sdw TO acedb;
# GRANT ALL ON TABLE pic_type_sdw TO apache;
# GRANT ALL ON TABLE pic_type_sdw TO cecilia;
# GRANT ALL ON TABLE pic_type_sdw TO azurebrd;
# CREATE INDEX pic_type_sdw_idx ON pic_type_sdw USING btree (joinkey);
#     
# 
# CREATE TABLE pic_value (
#     pic_name integer,
#     pic_users integer,
#     pic_category integer,
#     pic_type integer,
#     pic_value integer,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_value FROM PUBLIC;
# REVOKE ALL ON TABLE pic_value FROM postgres;
# GRANT ALL ON TABLE pic_value TO postgres;
# GRANT SELECT ON TABLE pic_value TO acedb;
# GRANT ALL ON TABLE pic_value TO apache;
# GRANT ALL ON TABLE pic_value TO cecilia;
# GRANT ALL ON TABLE pic_value TO azurebrd;
# CREATE INDEX pic_value_idx ON pic_value USING btree (joinkey);
# CREATE TABLE pic_value_sdw (
#     joinkey text,
#     pic_users text,
#     pic_category text,
#     pic_value text,
#     pic_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)
# );
# REVOKE ALL ON TABLE pic_value_sdw FROM PUBLIC;
# REVOKE ALL ON TABLE pic_value_sdw FROM postgres;
# GRANT ALL ON TABLE pic_value_sdw TO postgres;
# GRANT SELECT ON TABLE pic_value_sdw TO acedb;
# GRANT ALL ON TABLE pic_value_sdw TO apache;
# GRANT ALL ON TABLE pic_value_sdw TO cecilia;
# GRANT ALL ON TABLE pic_value_sdw TO azurebrd;
# CREATE INDEX pic_value_sdw_idx ON pic_value_sdw USING btree (joinkey);
# " );
# print "end\n";
__END__

# my $result = $conn->exec( "SELECT * FROM one_groups;" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)
