#!/usr/bin/perl -w
#

# Global Variables

my @f = </home/eimear/abstracts/PAPERS/WM/WM03/cnr*.txt>;
my $k = "/home/eimear/abstracts/PAPERS/WM/WM03/key";
my $outfile = "/home/eimear/abstracts/out2.ace";
my @directory;
my @file;
my %print_hash;				# hash of stuff to print
my @whole;



open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

%print_hash = ();        # initializes %print_hash
&processKey($k);

for $file (@f){
    ($j, $k, $l, $m, $n, $o, $p, $t, $d, $c, $f, $g, $h) = "";
    $wholefile = ""; 
    open (IN, "<$file") or die "Cannot open $file : $!";
    undef $/; 				# read the whole thing
    $wholefile = <IN>;
    close (IN) or die "Cannot close $file : $!";
    $wholefile =~ s/\<\/?[a-z]{1,3}\>//ig;
    $wholefile =~ s/\<sup\>/\(/ig;
    $wholefile =~ s/\<\/sup\>/\)/ig;
    $wholefile =~ s/&uuml;/u/ig;
    $wholefile =~ s/&auml;/a/ig;
    $wholefile =~ s/&ouml;/o/ig;
    $wholefile =~ s/&eacute;/e/ig;
    $wholefile =~ s/&aacute;/a/ig;
    $wholefile =~ s/&iacute;/i/ig;
    $wholefile =~ s/&oacute;/o/ig;
    $wholefile =~ s/&ccedil;/c/ig;
    $wholefile =~ s/&egrave;/e/ig;
   $wholefile =~ s/&nbsp;?//g;
    $wholefile =~ s/&\#9;?//g;
    $wholefile =~ s/&\#37;?/%/g;
    $wholefile =~ s/&\#43;?/+/g;
    $wholefile =~ s/&\#34;?/\"/g;
    $wholefile =~ s/&\#60;?/\</g;
    $wholefile =~ s/&\#62;?/\>/g;
    $wholefile =~ s/&\#145;?/\'/g;
    $wholefile =~ s/&\#147;?/\"/g;
    $wholefile =~ s/&\#148;?/\"/g;
    $wholefile =~ s/&\#149;?/~ /g;
    $wholefile =~ s/&\#150;?/\'/g;
    $wholefile =~ s/&\#151;?/-/g;
    $wholefile =~ s/&\#153;?/ (trademark) /g;
    $wholefile =~ s/&\#176;?/ degrees /g;
    $wholefile =~ s/&\#177;?/+\/-/g;
    $wholefile =~ s/&\#353;?/s/g;
    $wholefile =~ s/&\#8209;?/-/g;
    
    $wholefile =~ s/&copy;/copyright/g;
    $wholefile =~ s/&\#146;/\'/g;

    @wm = split(/\n/, $wholefile);  # splits by newline
    
    LINE: foreach $wm (@wm){
	if ($wm =~ /CTRL_NR/){
	    (undef, $val) = split /=\s+/, $wm;
	    $abs_number = $Khash{$val};
	    $abs_number =~ s/\s+//g;
	}
	if ($wm =~ /^Presenter_First_Name\s+=\s+\w+/){
	    $t = "";
	    chomp($wm);
	    ($key, $first) = split /=\s+/, $wm;
	    $t = $first;
	    $t =~ s/\s+$//g;
	    $t =~ s/\'//g;
	    $t =~ s/\.//g;
	}
	if ($wm =~ /^Presenter_Mid_Initial\s+=\s+\w+/){
	    chomp;
	    $c = "";
	    ($key, $last) = split /=\s+/, $wm;
	    next LINE unless $last =~ /\w+/;
	    $c = $last;
	    $c =~ s/\s+$//;
	    $c =~ s/\'//g;
	    $c =~ s/\.//g;
	}
	if ($wm =~ /^Presenter_Last_Name\s+=\s+\w+/){
	    $d = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $d = $last;
	    $d =~ s/\s+$//;
	    $d =~ s/\'//g;
	    $d =~ s/\.//g;
	}
#	if ($wm =~ /^Address1\s+=\s+\w+/){
#	    $e = "";
#	    chomp;
#	    ($key, $last) = split /=\s+/, $wm;
#	    $e = $last;
#	    $e =~ s/\s+$//;
#	    $e =~ s/\'//g;
#	    $e =~ s/\.//g;
#	}
	if ($wm =~ /^Department\s+=\s+\w+/){
	    $j = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $j = $last;
	    $j =~ s/\s+$//;
	    $j =~ s/\'//g;
	    $j =~ s/\.//g;
	}
	if ($wm =~ /^Institution\s+=\s+\w+/){
	    $k = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $k = $last;
	    $k =~ s/\s+$//;
	    $k =~ s/\'//g;
	    $k =~ s/\.//g;
	}
	if ($wm =~ /^Street\s+=\s+[A-Za-z]+/){
	    $l = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $l = $last;
	    $l =~ s/\s+$//;
	    $l =~ s/\'//g;
	    $l =~ s/\.//g;
	}
	if ($wm =~ /^City\s+=\s+[A-Za-z]+/){
	    $m = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $m = $last;
	    $m =~ s/\s+$//;
	    $m =~ s/\'//g;
	    $m =~ s/\.//g;
	}
	if (($wm =~ /^State\s+=\s+[A-Za-z]+/) || ($wm =~ /^Province\s+=\s+[A-Za-z]+/)) {
	    $n = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $n = $last;
	    $n =~ s/\s+$//;
	    $n =~ s/\'//g;
	    $n =~ s/\.//g;
	}

	if (($wm =~ /^Zip\s+=\s+[A-Za-z]+/) || ($wm =~ /^PostalCode\s+=\s+[A-Za-z]+/)) {
	    $o = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $o = $last;
	    $o =~ s/\s+$//;
	    $o =~ s/\'//g;
	    $o =~ s/\.//g;
	}
	if ($wm =~ /^Country\s+=\s+[A-Za-z]+/){
	    $p = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $p = $last;
	    $p =~ s/\s+$//;
	    $p =~ s/\'//g;
	    $p =~ s/\.//g;
	}

	if ($wm =~ /^Telephone\s+=\s+\w+/){
	    $f = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $f = $last;
	    $f =~ s/\s+$//;
	    $f =~ s/\'//g;
	    $f =~ s/\.//g;
	}
	if ($wm =~ /^Fax\s+=\s+\w+/){
	    $g = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $g = $last;
	    $g =~ s/\s+$//;
	    $g =~ s/\'//g;
	    $g =~ s/\.//g;
	}
	if ($wm =~ /^Email\s+=\s+\w+/){
	    $h = "";
	    chomp;
	    ($key, $last) = split /=\s+/, $wm;
	    $h = $last;
	    $h =~ s/\s+$//;
	    $h =~ s/\'//g;
	}

    }

    print OUT "Paper\t\[wm2003ab$abs_number\]\n";
    
    print OUT "Presenter\t$t\n" if defined($t);
    
    print OUT "Presenter_Middle\t$c\n" if defined($c);

    print OUT "Presenter_Last\t$d\n" if defined($d);

#    print OUT "Address\t$e\n" if defined($e);

    print OUT "Department\t$j\n" if defined($j);

    print OUT "Institute\t$k\n" if defined($k);

    print OUT "Street\t$l\n" if defined($l);

    print OUT "City\t$m\n" if defined($m);

    print OUT "State\t$n\n" if defined($n);

    print OUT "Zip\t$o\n" if defined($o);
    
    print OUT "Country\t$p\n" if defined($p);

    print OUT "Telephone\t$f\n" if defined($f);
    
    print OUT "Fax\t$g\n" if defined($g);

    print OUT "Email\t$h\n" if defined($h);
    
    print OUT "\n";
}
close (OUT) or die "Cannot close $outfile : $!";



sub processKey{
    $kf = shift;
    open (KF, $kf) || die "Cannot open $kf: $!";
    undef $/; 				# read the whole thing
    $all = <KF>;
    close (KF) or die "Cannot close $kf : $!";
    
    @all = split(/\n/, $all);  # splits by newline
    for (@all){
	($cnrlnum, $absnum) = split /-/, $_;
	$absnum =~ s/^0+//g;
	$absnum =~ s/[A-C]//g;
	$Khash{$cnrlnum} = $absnum;
    }
    return %Khash;
}

   
