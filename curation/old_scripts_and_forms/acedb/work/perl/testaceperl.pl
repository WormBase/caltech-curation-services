#!/usr/bin/perl

           use Ace;
#            # open a remote database connection
#            $db = Ace->connect(-host => 'beta.crbm.cnrs-mop.fr',
#                               -port => 20000100);
# 
#            # open a local database connection
#            $local = Ace->connect(-path=>'~acedb/my_ace');

           # local (non-server) database
$db = Ace->connect(-path  =>  '/home/acedb',
		   -program => '/home/acedb/bin/tace') || die "Connection failure: ",Ace->error;

# $db = Ace->connect() || die "Connection failure: ",Ace->error;


my @authors = $db->list('Author','Chan*');
print "There are ",scalar(@authors)," Author objects matching the last name.\n";
print "The first one's name is ",$authors[0],"\n";

$query = <<END;
Find Author Full_name = "*Chan*"
END
@ready_names= $db->fetch(-query=>$query);
foreach (@ready_names) { print "$_\n"; }
# while ($obj = $ready->next) {
#   print "$obj[0]\n";
# }

print "BREAK\n";

$query = <<END;
find Annotation Ready_for_submission ; follow gene ;
follow derived_sequence ; >DNA
END
@ready_dnas= $db->fetch(-query=>$query);

$ready = $db->fetch_many(-query=>$query);
while ($obj = $ready->next) {
  print "$obj[0]\n";
}

print "END here\n";

