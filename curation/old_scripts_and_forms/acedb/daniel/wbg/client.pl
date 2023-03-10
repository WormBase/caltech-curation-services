#!/usr/bin/perl

use strict;

# (1) input set up
# you can annotate upto 9 classes
my @classes_to_annotate = qw(Anatomy_name, Clone, Gene, 
                             Phenotype, Rearrangement, Sequence, 
                             Strain, Transgene, Variation);
#my @classes_to_annotate = qw(Gene, Rearrangement, Variation);

if (@ARGV < 2) {
    print "Usage: $0 <file to annotate> <format>\n";
    print "Eg   : $0 sample.txt XML\n";
    print "Eg   : $0 sample.txt HTML\n";
    die;
}
my $infile = $ARGV[0];
my $format = $ARGV[1];
if ( not ( ($format eq "XML") or ($format eq "HTML") ) ) {
    die "died: format cannot be '$format'. has to be either XML or HTML.\n";
}

# set classes line
my $classes_line = "Classes: @classes_to_annotate\n";

# set format to HTML (entities linked to wormbase) or XML (simple 
# <Gene>lin-11</Gene>) annotation
my $format_line =  "Format: $format\n";

# this text will be annotated
my $text_to_annotate = getText($infile); 


# (2) connect to server and get results
use Socket;
use constant END_OF_PAYLOAD  => "END OF PAYLOAD\n";
use constant ANNOTATION_HOST => "dev.textpresso.org";
use constant ANNOTATION_PORT => '8710';

my $end_of_payload = END_OF_PAYLOAD;
my $remote_host    = ANNOTATION_HOST;
my $remote_port    = ANNOTATION_PORT;

# create a socket
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));

# build the address of the remote machine
my $internet_addr = inet_aton($remote_host)
    or die "Couldn't convert $remote_host into an Internet address: $!\n";
my $paddr = sockaddr_in($remote_port, $internet_addr);

# connect
connect(SERVER, $paddr)
    or die "Couldn't connect to $remote_host:$remote_port: $!\n";

select((select(SERVER), $| = 1)[0]);  # enable command buffering

#print "sending data to server...\n";
print SERVER $classes_line . 
             $format_line .
             $text_to_annotate .  
             $end_of_payload;

#print "done.\n";

# (3) read and display the remote answer
#print "data returned by server...\n";
while (my $answer = <SERVER>) {
    print $answer;
}
# terminate the connection when done
close(SERVER);

sub getText {
    my $file = shift;
    open (IN, "<$file") or die ("died: no file $file: $!\n");
    my $ret;
    while (<IN>) {
        $ret .= $_;
    }
    return $ret;
}
