#!/usr/bin/perl -w
use strict;

use FileHandle;
use Data::Stag;
use Digest::MD5;
$SIG{'INT'} = \&handle_interrupt;
$SIG{'KILL'} = \&handle_interrupt;

# GLOBALS
our $DEBUG_LEVEL = 0;
our $warnings = 0;
our %conf = ();
our @ontids = ();
our %skipidh = ();
our %downloadedh = ();
our $DOWNLOADDIR = "obo-all";
our $SLEEP = 60;
our $MAX_DOWNLOAD_ATTEMPTS = 3;
our $LOCKFILE = "OBO-DOWNLOAD.LOCK";

our $PELLET = 'java -mx1024m -jar '.$ENV{HOME}.'/src/pellet/lib/pellet.jar';

our $GO = 'gene_ontology';
#our $ZF = 'zebrafish_anatomy';
our %multiontology_map =
  (molecular_function=>$GO,
   biological_process=>$GO,
   cellular_component=>$GO,
#   $ZF=>$ZF,
#   'zebrafish_stages'=>$ZF
   );

our @export_formats =
  qw[
     obo
     go_ont
     obo_xml
     owl
     chadoxml
     godb_prestore
     rdf
     tbl
     prolog
     error_report
     validation_report
     pellet_report
     stats
    ];
our $OWL_CLASSIFIED_BY_PELLET = 'owl-classified-by-pellet';
our $OBO_CLASSIFIED_BY_OBOEDIT = 'obo-classified-by-oboedit';
push(@export_formats,
     $OWL_CLASSIFIED_BY_PELLET,
     $OBO_CLASSIFIED_BY_OBOEDIT);

# GET ARGS
our $clean;
our $replace;
our $force;
our $nodownload;
our $downloadonly;
our %selected_ont = ();
our $outfile = "$DOWNLOADDIR/ontology_index.xml";
our $tarf;
our $max_failures;
while (@ARGV && $ARGV[0] =~ /^\-(\S+)/) {
    my $opt = shift @ARGV;
    if ($opt eq '-h' || $opt eq '--help') {
        usage();
        exit 0;
    }
    if ($opt eq '-f' || $opt eq '--force') {
        $force = 1;
    }
    if ($opt eq '-c' || $opt eq '--clean') {
        $clean = 1;
    }
    if ($opt eq '-r' || $opt eq '--replace') {
        $replace = 1;
    }
    if ($opt eq '--nodownload') {
        $nodownload = 1;
    }
    if ($opt eq '--downloadonly') {
        $downloadonly = 1;
    }
    if ($opt eq '--tar') {
        $tarf = 1;
    }
    if ($opt eq '--max-failures') {
        $max_failures = shift @ARGV;
    }
    if ($opt eq '--max-download-attempts') {
        $MAX_DOWNLOAD_ATTEMPTS = shift @ARGV;
    }
    if ($opt eq '--lockfile') {
        $LOCKFILE = shift @ARGV;
    }
    if ($opt eq '-d' || $opt eq '--debug') {
        $DEBUG_LEVEL = shift @ARGV;
    }
    if ($opt eq '-o' || $opt eq '--outfile') {
        $outfile = shift @ARGV;
    }
    if ($opt eq '-s' || $opt eq '--skip') {
        $skipidh{$_} = 1 foreach split(/\,/,shift @ARGV);
    }
    if ($opt eq '--ont') {
        $selected_ont{shift @ARGV} = 1;
    }
}

if (!-d $DOWNLOADDIR) {
    print `mkdir $DOWNLOADDIR`;
}

if (-f $LOCKFILE) {
    print STDERR "There is another obo-download process holding the lock in $LOCKFILE\nProcess ID: ";
    print STDERR `cat $LOCKFILE`;
    print STDERR "if this process is no longer running, then remove this file \n";
    exit 1;
}
`echo $$ > $LOCKFILE`;


my @conffiles = @ARGV;
@conffiles = ("../cgi-bin/ontologies.txt",
              "../cgi-bin/mappings.txt")
  unless @conffiles;

my $writer = Data::Stag->getformathandler('xml');
$writer->file($outfile);
$writer->start_event('obo_metadata');
my $time = time;
my $localtime = localtime $time;

$writer->event(time_started=>[['@'=>[[unix=>$time]]],
                              ['.'=>$localtime]]);

my @all_ontids = ();
my $n_done = 0;
my $n_failed = 0;
read_conffiles(@conffiles);

if (%selected_ont) {
    print STDERR "Sfiltering: @ontids\n";
    @ontids = grep {$selected_ont{$_}} @ontids;
    trace2("Ont IDs: @ontids");
}
@ontids = grep {!$skipidh{$_}} @ontids;
push(@all_ontids, @ontids);

#print Dump \%conf;

trace2("Ont IDs: @ontids");
if ($clean) {
    foreach my $ontid (@ontids) {
        my $ontdir = ontdir($ontid);
        system("rm -rf $ontdir") if -d $ontdir;
    }
    trace1("Clean completed");
    exit_and_remove_lock(0);
} else {
    foreach my $ontid (@ontids) {
        $writer->start_event('ont');
        $writer->event('@'=>[[id=>$ontid]]);
        my $ok = download_and_export($ontid);
        $writer->end_event;
        if ($ok) {
            $n_done++;
        } else {
            $n_failed++;
        }
    }
}

$writer->event(ontologies_indexed=>$n_done);
$writer->event(ontologies_not_indexed=>$n_failed);

my $oldtime=$time;
$time = time;
$localtime = localtime $time;
my $deltatime = $time-$oldtime;

$writer->event(time_completed=>[['@'=>[[unix=>$time],[total_time=>$deltatime]]],
                                ['.'=>$localtime]]);

trace1("Build Completed!");
trace1("Total ont IDs: ".scalar(@all_ontids));
trace1("Done: $n_done");
trace1("Fail: $n_failed") if $n_failed;
if ($warnings) {
    trace1("Warnings: $warnings");
}
$writer->end_event;
$writer->finish;

# write an OWL imports file for every ID-space
my %onts_by_idspace = ();
foreach my $ont (keys %conf) {
    my $h = $conf{$ont};
    if ($h->{type} && $h->{type} ne 'ontology') {
        # do not count mapping files
        # (perhaps we want to do this in some circumstances, if they are approve?)
    }
    else {
        my $ns = $h->{namespace};
        push(@{$onts_by_idspace{$ns}},
             $ont);
    }
}
`mkdir owl` unless -d 'owl';
foreach my $idspace (keys %onts_by_idspace) {
    my $fn = "owl/$idspace.owl";
    if ($idspace) {
        my $onts = $onts_by_idspace{$idspace} || [];
        if (!@$onts) {
            scold("no ontologies for IDspace: $idspace");
        }
        elsif (@$onts == 1) {
            my $ont = $onts->[0];
            `cd owl && rm $idspace.owl`;
            `cd owl && ln -fs ../$DOWNLOADDIR/$ont/$ont.owl $idspace.owl`;
            `cd owl && ln -fs $idspace.owl $idspace`;
            `cd owl && ln -fs $idspace.owl $idspace`;
        }
        else {
            # this ID-space corresponds to multiple ontologies
            # generate an imports file
            my $fh = FileHandle->new(">$fn");
            if ($fh) {
                print_owl_import_file($fh, @$onts) if @$onts;
                $fh->close;
                `cd owl && ln -fs $idspace.owl $idspace`;
            }
            else {
                scold("cannot write $fn");
            }
        }
    }
    else {
        scold("empty idspace: $idspace");
    }
}


# remove unfinished files

if (system("find $DOWNLOADDIR -name '*.tmp' -exec rm -f {} \\;")) {
    scold("problem removing tmps");
}

if (defined($max_failures) && $n_failed > $max_failures) {
    scold("Too many ontologies failed to be indexed [max=$max_failures]");
    exit_and_remove_lock(1);
}

if ($tarf) {
    my $cmd = 
      "tar cf $DOWNLOADDIR.tar $DOWNLOADDIR/ && gzip --force $DOWNLOADDIR.tar";
    if (system($cmd)) {
        scold("problem: $cmd");
    }
    foreach my $fmt (@export_formats) {
        $fmt =~ s/go_ont/go/;
        $fmt =~ s/prolog/pro/;
        $cmd = 
          "tar cf $DOWNLOADDIR-$fmt.tar $DOWNLOADDIR/*/*.$fmt && gzip --force $DOWNLOADDIR-$fmt.tar";
        if (system($cmd)) {
            scold("problem: $cmd");
        }
    }
}

exit_and_remove_lock(0);
# ------- END OF MAIN CODE --------

# ---------------------------------------------------------------
# SUBROUTINES
# ---------------------------------------------------------------

sub exit_and_remove_lock {
    my $err = shift;
    unlink $LOCKFILE;
    exit $err;
}

sub handle_interrupt {
    print STDERR "INTERRUPT!\n";
    exit_and_remove_lock(1);
}

# read_conffiles(@files) -- sets %conf and @ontids

#  tag-value version
sub read_conffiles {
    my @files = @_;

    foreach my $f (@files) {

        open(F,$f) || death("cannot read $f");
        my $ontid;
        my $line = 0;
        my %rowh;

        my $id;
        while (<F>) {
            chomp;
            $line++;

            next unless $_;

            my ($k,$v);
            if (/^(\w+)\s+(.*)/) {
                $k = $1;
                $v = $2;
            } else {
                scold("not tag value: $_");
                next;
            }
            if ($k eq 'id') {
                $id = $v;
                %rowh = ();
                push(@ontids,$id);
                $conf{$id} = {};
            }
            if ($k eq 'format') {
                if ($v =~ /plain/ && $id =~ /ncbi_taxonomy/) {
                    $v = 'ncbi_taxonomy';
                }
            }
            if ($k eq 'status' && $v =~ /deprecated/i) {
                trace0("will ignore $id (deprecated)");
                $skipidh{$id} = 1;
            }
            if ($k eq 'download') {
                my @parts = split(/\s*\|\s*/,$v);
                $conf{$id}->{filename} = shift @parts;
                my $urlpair = shift @parts;
                if ($urlpair) {
                    my ($url,$defurl) = split(/\,/,$urlpair);
                    $conf{$id}->{url} = $url;
                    $conf{$id}->{defurl} = $defurl if $defurl;
                } else {
                    scold("no URL pair in $id: $v");
                }
                if (@parts) {
                    $conf{$id}->{url2} = shift @parts;
                }
                if (@parts) {
                    scold("Ignoring download: @parts [in $id]");
                }
            }
            if ($k eq 'source' && $v =~ /\S+/ &&
                !$conf{$id}->{url}) {
                if ($v =~ /\|/) {
                    scold("pipe in source line not allowed ($id)");
                    my @parts = split(/\s*\|\s*/,$v);
                    $conf{$id}->{url} = shift @parts;
                    if (@parts) {
                        scold("Ignoring download: @parts [in $id]");
                    }
                } else {
                    my @parts = split(/\s*\,\s*/,$v);
                    $conf{$id}->{url} = shift @parts;
                    if (@parts) {
                        scold("Ignoring download: @parts [in $id]");
                    }
                }
            }
            $conf{$id}->{$k} = $v;
        }
        #use Data::Dumper;
        #print Dumper \%conf;
        close(F);
    }
}

# canonicalise format
sub fix_format {
    my $rowh = shift;
    my $f = $rowh->{format};
    $f =~ s/\s*\|.*//;
    my $nf;
    $nf = 'owl' if $f =~ /owl/i;
    $nf = 'obo' if $f =~ /obo/i;
    $nf = 'go' if $f =~ /go/i;
    $nf = 'ncbi_taxonomy' if $f =~ /plain/i && $rowh->{id} eq 'ncbi_taxonomy';
    $nf = 'protege' if $f =~ /protege/i;
    if (!$nf) {
        $nf = $f;
        $rowh->{format_unknown} = 1;
    }
    $rowh->{format} = $nf;
}

# prepare($ontid) -- makes a dir
sub prepare_dir {
    my $ontid = shift;
    my $ontdir = ontdir($ontid);
    my @parts = split(/\//,$ontdir);
    my $curdir = '';
    while (@parts) {
        $curdir .= shift @parts;
        `mkdir $curdir` unless -d $curdir;
        if (@parts) {
            $curdir .= '/';
        }
    }
    return;
}

sub ontdir {
    my $id = shift;
    "$DOWNLOADDIR/$id"
}

# make_path($ontid,$type) -- returns relative path to a formatted file
sub make_path {
    my $ontid = shift;
    my $type = shift;
    my $ontdir = ontdir($ontid);
    $type =~ s/prolog/pro/;
    $type =~ s/go_ont/go/;
    "$ontdir/$ontid.$type";
}

# download($ontid) -- downloads an ontology and exports data
# returns zero if fails
sub download_and_export {
    my $ontid = shift;
    my $already_downloaded = shift;
    my $ontdir = ontdir($ontid);
    my $onth = $conf{$ontid};
    my $ok = 1;
    foreach my $k (keys %$onth) {
        next if $k eq 'id';
        my $kname = $k;
        $kname =~ s/namespace/idspace/;
        $writer->event($k,$onth->{$k});
    }
    my $fmt = $onth->{format} || '';
    trace0("downloading $ontid [$fmt]");
    if ($onth->{format_unknown}) {
        scold("unknown format: $fmt");
    }
    return unless $fmt;
    prepare_dir($ontid);

    # some ontologies (eg GO) are actually multiple ontologies
    # in one file/resource
    #  example:
    #   the sourceid for molecular_function is gene_ontology
    my $sourceid = $multiontology_map{$ontid};
    my $sourcepath;

    # fetch sourcepath
    if ($sourceid) {
        trace1("making $ontid from $sourceid");
        $conf{$sourceid}->{url} = $conf{$ontid}->{url};
        $conf{$sourceid}->{format} = $conf{$ontid}->{format};
        my $sourcepath_orig = download_source_ontology($sourceid);
        my $intermediate_oboxml = export_file($sourceid,$fmt,'obo_xml');
        if ($intermediate_oboxml) {
            $sourcepath = make_path($ontid,'obo_xml');
            if (more_recent($sourcepath,$intermediate_oboxml) &&
                !$replace) {
                trace0("Using existing file [$sourcepath] which is more recent than $intermediate_oboxml");
            }
            else {
                my $err = 
                  runcmd("go-apply-xslt oboxml_filter $intermediate_oboxml --stringparam namespace $ontid > $sourcepath.tmp && mv $sourcepath.tmp $sourcepath"); 
                if ($err) {
                    trace0("Could not extract ontology $ontid from source $sourceid");
                }
            }
            export_file($ontid,'obo_xml','obo');
        }
        else {
            trace0("Could not make obo_xml from $sourceid");
        }
    }
    else {
        $sourcepath = download_source_ontology($ontid);
    }  # -- done fetching sourcepath
    if (!$sourcepath) {
        trace0("Could not download: $ontid");
        $writer->event(problem=>"Source not available at specified URL as recognised format");
        return;
    }

    if ($downloadonly || $already_downloaded) {
        # do nothing
    }
    else {
        export_ontology($ontid,$fmt);
    }
    write_stats($ontid);

    return $ok;
}

sub export_ontology {
    my $ontid = shift;
    my $fmt = shift;

    # can't handle protege files yet
    return if $fmt eq 'protege';

    if ($fmt eq 'owl' || $fmt eq 'gene_info.gz') {
        export_ontology_via_blip($ontid,$fmt);
        return;
    }

    # obo-xml is the 'base' format from which others are made
    export_file($ontid,$fmt,'obo_xml');
    # export others from obo-xml
    foreach my $export_fmt (@export_formats) {
        next if $export_fmt eq 'obo_xml';
        next if $export_fmt eq 'pellet_report';
        next if $export_fmt =~ /classified/;
        #next if $export_fmt eq $fmt;
        export_file($ontid,'obo_xml',$export_fmt,$fmt);
    }
    export_file($ontid,'owl','pellet_report');
    export_file($ontid,'owl',$OWL_CLASSIFIED_BY_PELLET);
    export_file($ontid,'obo',$OBO_CLASSIFIED_BY_OBOEDIT);
    return;
}

sub export_ontology_via_blip {
    my $ontid = shift;
    my $from = shift;
    export_file($ontid,$from,'pro');
    export_file($ontid,'pro','obo');

    foreach my $export_fmt (@export_formats) {
        next if $export_fmt eq 'pro';
        next if $export_fmt eq 'obo';
        next if $export_fmt eq 'pellet_report';
        next if $export_fmt =~ /classified/;
        export_file($ontid,'obo',$export_fmt,$from);
    }
    export_file($ontid,'owl','pellet_report');
    export_file($ontid,'owl',$OWL_CLASSIFIED_BY_PELLET);
    export_file($ontid,'obo',$OBO_CLASSIFIED_BY_OBOEDIT);
}


sub download_source_ontology {
    my $ontid = shift;
    my $loc = $conf{$ontid}->{url};
    my $fmt = $conf{$ontid}->{format};
    my $path = make_path($ontid, $fmt);

    if ($ontid eq 'ncithesaurus' && $loc =~ /EVS\//) {
        $loc = "http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl"
    }
    return $path if $nodownload;
    return $path if $downloadedh{$ontid};

    prepare_dir($ontid);

    if (!$loc) {
        scold("Cannot figure out how to download $ontid");
        return 0;
    }

    if ($loc =~ /\/$/) {
        scold("Require path to file, not directory: $loc [in $ontid]");
        return 0;
    }
    # sourceforge weirdness
    if ($loc =~ /viewcvs\.py/) {
        $loc =~ s/viewcvs\.py/viewcvs\.py\/\*checkout*/;
        $loc .= "?view=checkout";
    }
    elsif ($loc =~ /viewcvs/) {
        # po site at cshl does not use .py suffix
        $loc =~ s/viewcvs/viewcvs\/\*checkout*/;
        $loc .= "?view=checkout";
    }
    elsif ($loc =~ /ftp/) {
        # ok
        $loc =~ s/^ftp\./ftp:\/\/ftp\./;
    }
    elsif ($loc =~ /http:/) {
        if ($loc =~ /prdownload/) {
            scold("cannot handle this yet: $loc");
            return;
        }
        # ok
    }
    else {
        trace0("unparseable url \"$loc\" for $ontid");
        return;
    }

    my $attempts = 0;
    my $download_succeeded = 0;
    while (!$download_succeeded &&
           $attempts < $MAX_DOWNLOAD_ATTEMPTS) {
        $attempts++;
        # we make sure timestamp is now (we may want to regenerate dependent files)
        my $cmd = "wget $loc -O $path.tmp && mv $path.tmp $path && touch $path";
        if (runcmd($cmd)) {
            # sometimes sourceforge randomly fails...
            trace0("could not download $loc on attempt# $attempts");
            # wait a while before trying again
            trace0("waiting $SLEEP seconds, then trying again");
            sleep $SLEEP;
        }
        else {
            $download_succeeded = 1;
        }
    }
    if (!$download_succeeded) {
        scold("FILE NOT FOUND: ONT $ontid AT: $loc");
        return;
    }

    if (check_no_html($path)) {
        scold("Incorrect location specified for ONT:$ontid AT $loc");
        unlink $path;
        return;
    }
    # EVOC is stored as one tar file
    if ($loc =~ /\.tar/) {
        my @files = split(/\n/,`tar -xvf $path`);
        unlink($path);
        my @obofiles = ();
        foreach (@files) {
            if (/(.*)\.obo/) {
                push(@obofiles,$_);
#                my $newont = $1;
#                my $subont = $ontid."_".$newont;  # e.g. evoc_anatomy
#                my $subpath = ontdir($subont);
#                prepare_dir($subont);
#                `mv $_ $subpath/$subont.obo`;
#                download_and_export_ontology($subont,'obo');
            }
            else {
                unlink($_);
            }
        }
        runcmd("go2obo -p obo @obofiles > $path");
    }
    $downloadedh{$ontid} = 1;
    return $path;
}

sub write_stats {
    my $ontid = shift;
    my $f = make_path($ontid,'stats');
    return unless -f $f;
    my $ifh = FileHandle->new($f);
    if (!$f) {
        scold("can't read $f");
        return 0;
    }
    my @stats = ();
    my $namespace_used;
    while (<$ifh>) {
        chomp;
        if (/^Ontology:\s+(.*)/) {
            if ($1 ne $ontid) {
                scold("expected $ontid got $1 in stats file $f");
                if ($namespace_used) {
                    scold("two different ids: $1 and $namespace_used. bailing");
                    last;
                }
            }
            $namespace_used = $1; # remember which ontology we are in
        }
        else {
            s/\#\#.*//;
            if (/^\s+(\w+):\s*(.*)/) {
                push(@stats,[$1=>$2]);
            }
        }
    }
    $ifh->close;
    if (@stats) {
        $writer->event(stats=>[['@'=>[@stats]]]);
    }
    return 1;
}

# ------------------------------------------------------------
# CONVERTERS
# ------------------------------------------------------------

sub export_file {
    my ($ontid,$from,$to,$base_fmt) = @_;
    my $t1=time;
    my $out = export_file1($ontid,$from,$to,$base_fmt);
    my $t2=time;
    my $tdelta = $t2-$t1;

    # get statistics on file size, etc
    if ($out && -f $out) {
        my @stat = stat($out);
        my $ifh = FileHandle->new($out);
        my $checksum = '';
        if ($ifh) {
            my $ctx = Digest::MD5->new;
            $ctx->addfile($ifh);
            $checksum = $ctx->hexdigest;
            $ifh->close;
        }
        else {
            scold("problem with $out");
        }
        $writer->event(export=>[['@'=>[[format=>$to],
                                       [path=>$out],
                                       [md5=>$checksum],
                                       [time_generated=>$t2],
                                       [time_taken_to_generate=>$tdelta],
                                       [size=>$stat[7]]]]]);
    }
    else {
        $writer->event(export=>[['@'=>[[format=>$to],[problem=>'true']]]]);
    }
    return $out;
}

sub export_file1 {
    my ($ontid,$from,$to,$base_fmt) = @_;
    $base_fmt = '' unless defined $base_fmt;
    my $src = make_path($ontid, $from);
    my $out = make_path($ontid, $to);
    if ($to =~ /classified/ && $conf{$ontid}->{type} ne 'logical_definitions') {
        return;
    }
    if ($to eq $base_fmt) {
        return $out;
    }
    if ($from eq $to) {
        return $out;
    }
    if (-f $out && more_recent($out, $src)) {
        if (!$replace) {
            trace0("Using existing file [$out] which is more recent than $src");
            return $out;
        }
    }

    my $parser = $from;
    if ($from eq 'go') {
        $parser = 'go_ont';
    }

    my $exec;
    if ($to eq 'chadoxml') {
        $exec = 'go2chadoxml';
    }
    elsif ($from eq 'pro' && $to eq 'obo') {
        $exec = "blip io-convert -f ontol_db:pro -to obo -i";
    }
    elsif ($from eq 'gene_info.gz' && $to eq 'pro') {
        $exec = "blip io-convert -f gzip/gene_info -to ontol_db:pro -u gene_bridge_to_class -i";
    }
    elsif ($from eq 'owl' && $to eq 'pro') {
        my $blip_args = '';
        if ($ontid =~ /ncit/i) {
            $blip_args = "-u ontol_owlmap_from_ncithesaurus";
        }
        if ($ontid eq 'obi') {
            $blip_args = "-u ontol_owlmap_from_obi";
        }
        $exec = "blip $blip_args io-convert -f owl -to ontol_db:pro -i";
    }
    elsif ($to eq 'owl') {
        $exec = 'go2owl';
    }
    elsif ($to eq 'godb_prestore') {
        $exec = 'go2godb_prestore';
    }
    elsif ($to eq 'error_report') {
        $exec = 'go2error_report';
    }
    elsif ($to eq 'validation_report') {
        $exec = 'blip -debug io -f obo_xml ontol-validate -i';
    }
    elsif ($to eq 'pellet_report') {
        $exec = "$PELLET -if";
        $src = "file:$src"; # pellet needs a URI
    }
    elsif ($to eq $OWL_CLASSIFIED_BY_PELLET) {
        $exec = "$PELLET -c RDF -if";
        $src = "file:$src"; # pellet needs a URI
    }
    elsif ($to eq 'stats') {
        $exec = 'blip -debug io -f obo_xml ontol-stats -i';
    }
    else {
        $exec = "go2fmt.pl -p $parser -w $to";
    }

    if (($exec =~ /validate/ || $exec =~ /stats/) && $ontid =~ /^fly_development/) {
        # skipping stats generation for this ontology -
        # takes too long
        return 0;
    }
    if ($to eq 'chadoxml' && $ontid eq 'ncbi_taxonomy') {
        # todo - this seems to get stuck in an endless loop
        return 0;
    }

    my $cmd = 
      sprintf("$exec $src > $out.tmp",
              $from,$to);

    if ($to eq $OBO_CLASSIFIED_BY_OBOEDIT) {
        $cmd = "obo2obo -o -saveimpliedlinks $out.tmp $src";
    }

    $cmd .= " && mv $out.tmp $out";


    my $def = make_path($ontid, 'def');
    if ($from eq 'go' && $to eq 'obo') {
        $cmd = go_to_obo($ontid,$from,$to,$def);
    }
    elsif ($from eq 'obo' && $to eq 'go') {
        $cmd = obo_to_go($from,$to,$def);
    }
    else {
    }

    if (runcmd($cmd)) {
        scold("problem running: $cmd");
        return 0;
    }
    return $out;
}

# use DAG-Edit supplied-scripts to make conversion
sub go_to_obo {
    my $ontid = shift;
    my $ontfile = shift || death("need ontfile in go_to_obo");
    my $obofile = shift;
    my $deffile = shift;

    my $defopt = $deffile ? "-def $deffile" : "";
    my $cmd = 
      "flat2obo $defopt $ontfile -defaultns $ontid -o $obofile";
    return $cmd;
}

sub obo_to_go {
    my $obofile = shift || death("need ontfile in go_to_obo");
    my $ontfile = shift;
    my $deffile = shift;

    my $defopt = $deffile ? "-def $deffile" : "";
    my $cmd = 
      "obo2flat $defopt $obofile -o $ontfile";
    return $cmd;
}

sub more_recent {
    my ($f1,$f2) = @_;
    printf "$f1 [%s] <=> $f2 [%s]\n",
      ftime($f1), ftime($f2);
    ftime($f1) > ftime($f2);
}

sub ftime {
    my $f = shift;
    my @s = stat($f);
    return $s[9] || 0;
}

sub check_no_html {
    my $f = shift;
    # this command returns false if there is no html
    return !system("grep 'doctype html public' $f");
}

# ------------------------------------------------------------
# 
# ------------------------------------------------------------

# runcmd($cmd) -- runs a command in O/S
sub runcmd {
    my $cmd = shift;
    my $errref = shift;
    trace2("CMD: $cmd");
    my $err = system("(($cmd) > OUT) >&  ERR");
    print STDERR "STDERR [lines 1-50]:\n";
    print STDERR `head -50 ERR`;
    if ($err) {
        print "STDOUT [lines 1-50]:\n";
        print `head -50 OUT`;
        return 1;
    }
    return 0;
}

# ------------------------------------------------------------
# OWL imports
# ------------------------------------------------------------
sub print_owl_import_file {
    my $fh = shift;
    my @onts = @_;
    print $fh <<EOM;
<?xml version="1.0"?>
<rdf:RDF
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#">
  <owl:Ontology rdf:about="">
EOM
    ;
    foreach (@onts) {
        printf $fh '      <owl:imports rdf:resource="../%s/%s/%s.owl"/>',$DOWNLOADDIR,$_,$_;
        print $fh "\n";
    }
    print $fh "  </owl:Ontology>\n";
    print $fh "</rdf:RDF>\n";

}


# ------------------------------------------------------------
# TRACING AND DIAGNOSTICS
# ------------------------------------------------------------

sub trace0 { trace(0, @_) }
sub trace1 { trace(1, @_) }
sub trace2 { trace(2, @_) }

sub trace {
    my $lev = shift;
    if ($lev >= $DEBUG_LEVEL) {
        print "@_\n";
    }
}

sub scold {
    $warnings++;
    print STDERR "@_\n";
}
sub death {
    print STDERR "ERROR\n@_\n";
    if ($force) {
        $warnings++;
        return;
    }
    exit 1;
}

# ------------------------------------------------------------
# usage
# ------------------------------------------------------------
sub usage {
    print <<EOM;
obo-builder.pl [OPTIONS] <<path to ontologies.txt>>
 Options:
  -o --out      FILE          name of generated metadata xml file
  -c --clean                  Clear all existing exports, then exit
  -r --replace                Always download even if file exists
  -f --force                  Ignore errors and charge on regardless
  -d --debug    LEVEL         verbose mode, LEVEL>0
     --ont      ID            only do this ontology
  -s --skip     ID            skip this ontology
     --downloadonly           only download, no exports
     --nodownload             no download, export only
     --max-failures NUM       return err if NUM ontologies failed indexing
     --max-download-attempts  default 3: (sourceforge often down)
     --tar                    creates tarballs on completion

This script downloads and generates ontology files in a variety of formats.
It generates one directory per ontology, named by ontology ID/namespace
This directory should contain all required files

It also generates a metadata XML file (default name
obo-all/ontology_index.xml)

if no ontologies.txt file is specified, will look in ../cgi-bin/ontologies.txt

EOM
;
}
