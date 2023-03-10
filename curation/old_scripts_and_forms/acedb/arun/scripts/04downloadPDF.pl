#!/usr/bin/perl -w
#
# Purpose: Download PDFs from specific journals. Needs as input a tab-delimited 
# file of the following format:
# <journal name> <pmid> <year> <volume> <issue> <firstpage>
# 
#
# Authors:  Hans-Michael Muller, Arun Rangarajan
# Date   :  February 2006,       Oct-Nov 2006

if (@ARGV < 4) { die "

USAGE: $0 <file with journalinfo> <good pdf directory> <bad pdf directory> <basedir>



SAMPLE INPUT:  $0 pubmed.dat ./elegans/pdf ./elegans/tmp /home/arun/daniel/scripts/elegans
\n
";}

##############################################################################

use strict;
use HTTP::Request;
use LWP::UserAgent;

my $infofile = $ARGV[0];
my $pdfdir   = $ARGV[1];
my $baddir   = $ARGV[2];
my $basedir  = $ARGV[3];

# Get the journals in different categories
my $sfx_abstract   = GetInputFile("sfx_citation_abstract_html_url.in");
my $sfx_pdf_num    = GetInputFile("sfx_pdf_num.in");
my $science_direct = GetInputFile("science_direct.in");
my $springer_link  = GetInputFile("springer_link.in");
my $nature         = GetInputFile("nature.in");

# Non-downloadable journals, either unavailable or not conducive to auto-download
my %Non_Downloadable_Journals;
GetNdJournals(\%Non_Downloadable_Journals, "non_downloadable_journals.in");

# Output file handles
open (NONDOWN, ">./output/non_downloadable.out") || die ("Couldn\'t open couldnt_download.out for writing.\n");
open (INVALID_URL, ">./output/invalid_url.out") || die ("Couldn\'t open invalid_url.out for writing.\n");
open (NO_URL, ">./output/no_url.out") || die ("Couldn\'t open no_url.out for writing.\n");

my %unaccounted_j;

open (INFO, "<$infofile");
while (my $line = <INFO>)
{   
	print "line = $line\n";
	chomp($line);
    my ($jo, $pmid, $ye, $vo, $is, $pa) = split (/\t/, $line);
	if (NonDownloadableJournal($jo, \%Non_Downloadable_Journals))
	{
		print NONDOWN "$pmid\n";
		print "Non-downloadable: pmid written to non_downloadable.out\n";
		print "____________________________________________________________________________________\n";
		next;
	}

    if ( (! -e "$pdfdir/$pmid.pdf") )
	{	
		# For some strange occurences like $vo = "5 Is 3", $is = "" instead of $vo = "5" and $is = "3"
		if ($is eq "")
		{	if ($vo =~ /(\d+)\s+(\w+)\s+(\d+)/)
			{	$vo = $1;
				$is = $3;
			}
		}
	
		my $url = "";

		if ($jo =~ /^$sfx_abstract$/) 
		{	$url = Sfx1($pmid);
		} 
		if ($jo =~ /^$sfx_pdf_num$/) 
		{	$url = Sfx2($pmid);
		} 
		elsif ($jo =~ /^$science_direct$/) 
		{	$url = ScienceDirect($jo, $pmid, $ye);
		}
		elsif ($jo =~ /^$springer_link$/)
		{	$url = SpringerLink($jo, $pmid, $ye);
		}
		elsif ($jo =~ /^$nature$/)
		{	$url = NatureGeneric($pmid);
		}
		elsif ($jo eq "Biochemistry")
		{	$url = Sfx3($pmid);
		}
		elsif ($jo eq "Nucleic Acids Res")
		{	$url = Nucleic_Acids_Res($pmid, $vo, $is, $pa, $basedir);
		}
		elsif ($jo eq "Curr Biol")
		{	$url = Curr_Biol($jo, $pmid, $ye, $vo, $is, $pa, $basedir);
		}
		elsif ($jo eq "DNA Cell Biol")
		{	$url = DNA_Cell_Biol($pmid);
		}
		elsif ($jo eq "Int J Mol Med")
		{	$url = Int_J_Mol_Med($ye, $vo, $is, $pa);
		}
		elsif ($jo eq "Genes Genet Syst")
		{	$url = Genes_Genet_Syst($vo, $is, $pa);
		}
		elsif ($jo eq "Genome Biol")
		{	$url = Genome_Biol($ye, $vo, $is, $pa);
		}
		elsif ($jo eq "J Genet")
		{	$url = J_Genet($vo, $is, $pa);
		}
		elsif ($jo =~ /^BMC /)
		{	$url = BMC_Generic($pmid, $vo, $is, $pa);
		}
		elsif ($jo eq "Biophys J")
		{	$url = Biophys_J($pmid);
		}
		elsif ($jo eq "Nat Neurosci")
		{	$url = Nat_Neurosci($pmid);
		}
		elsif ($jo eq "Biochem Soc Trans")
		{	$url = Biochem_Soc_Trans($pmid);
		}
		else
		{	$unaccounted_j{$jo} = 1;
		}

		if (! $url =~ /.+/)
		{	$url = "";
			if (! ($jo eq "Science"))
			{
				print "Empty URL: pmid written to couldnt_download.out \& line in no_url.out\n";
				print NO_URL "$jo\t$pmid\t$ye\t$vo\t$is\t$pa\n";
				#print "Type something and hit ENTER.\n";
				#my $dummy = <STDIN>;	
				#print "Dummy is $dummy\n";
			}
		}
		
		print "URL = \'$url\'\n";
		
		if ($url ne "") 
		{	
		    my $cont = getwebpage($url);
		    if ($cont =~ /^\%PDF-/) 
			{	dumptext($cont, "$pdfdir/$pmid.pdf");
				print "$pmid\.pdf added to pdf directory.\n";
		    } else 
			{	
				if (! ($jo eq "Science"))
				{
					dumptext($cont, "$baddir/$pmid.pdf");
					print "Invalid URL: pmid written to couldnt_download.out \& line written to invalid_url.out\n";
					print INVALID_URL "$jo\t$pmid\t$ye\t$vo\t$is\t$pa\n";
					#print "Type something and hit ENTER\n";
					#my $dummy1 = <STDIN>;
					#print "Dummy is $dummy1\n";
				}
		    }
		} 
	
		# Full-text journals
		if ($jo eq "Science")
		{	Science_FullText($pmid, $vo, $is, $pa, $basedir);
		}
    }

	print "____________________________________________________________________________________\n";
}

open (UNACCOUNTED_J, ">./output/unaccounted_j.out") || die ("Couldn\'t open unaccounted_j.out for writing.\n");
foreach (keys %unaccounted_j)
{	print UNACCOUNTED_J "$_\n";
}
close (UNACCOUNTED_J);

close (INFO); close (INVALID_URL); close (NO_URL); close (NONDOWN);

### Sub-routines for getting URLs for various journals available through Caltech

sub Biophys_J
{	my $url;
	my $pmid = shift;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ / HREF=\"(\S+?)\?\">/o)
		{	my $v1 = $1.".pdf";
			$v1 =~ s/framed//;
			$url = "http://www.biophysj.org".$v1;
		}
   	}
	return $url;
} 

sub BMC_Generic
{	my $pmid = shift;
	my $vo = shift;
	my $is = shift;
	my $pa = shift;
	my $url;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
    my $var1 = "";
   	my $var2 = "";
   	if ($auxcont =~ /BMC [\w\s]+\[(\S+)-(\S+)\]/) 
	{	$var1 = $1;
		$var2 = $2;
   	}
    if ( $var1 . $var2 ne "") 
	{	$url = "http://www.biomedcentral.com/content/pdf/$var1-$var2-$vo-$pa.pdf";
   	}
	return $url;
} 

sub J_Genet
{	my $vo = shift;
	my $is = shift;
	my $pa = shift;
	my $url = "http://www.ias.ac.in/jgenet/Vol$vo"."No$is/$pa.pdf";
	return ($url);
}

sub Genes_Genet_Syst
{	my $vo = shift;
	my $is = shift;
	my $pa = shift;
	return ("http://www.jstage.jst.go.jp/article/ggs/$vo/$is/$pa/_pdf");
}

sub Int_J_Mol_Med
{	my $ye = shift;
	my $vo = shift;
	my $is = shift;
	my $pa = shift;
	return ("http://147.52.72.117/IJMM/$ye/volume$vo/number$is/$pa.pdf");
}

sub Genome_Biol
{	my $ye = shift;
	my $vo = shift;
	my $is = shift;
	my $pa = shift;
	return ("http://genomebiology.com/content/pdf/gb-$ye-$vo-$is-$pa.pdf");
}

sub Nucleic_Acids_Res
{	my $url;
	my $pmid = shift;
	my $vo = shift;
	my $is = shift;
	my $pa = shift;
	my $basedir = shift;

	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ / href=\"(\S+)\">v.$vo\($is\)/)
		{	my $auxurl2 = "http\:\/\/www.pubmedcentral.gov/" . $1;
			print "aux URL2 = $auxurl2\n";
			my $auxcont2 = getwebpage($auxurl2);

			open (TITLE, "<$basedir/title/$pmid");
			my $title = "";
			while (<TITLE>)
			{	chomp;
				$title = $_;
			}
			$title =~ s/\(/\\\(/g;
			$title =~ s/\)/\\\)/g;
			$title =~ s/\[/\\\[/g;
			$title =~ s/\]/\\\]/g;
			$title =~ s/\+/\\\+/g;
			$title =~ s/\*/\\\*/g;

			if ($auxcont2 =~ /($title(.*)href=\"(\S+=pdf)">PDF)/)
			{	my $fullmatch = $1;
				$fullmatch =~ / href=\"(\S+pdf)\"/;
				my $tmp = $1;
				$url = "http:\/\/www.pubmedcentral.gov\/" . $tmp;
			}
		}
   	}
	return $url;
} 

sub Biochem_Soc_Trans
{	my $url;
	my $pmid = shift;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ / href=\"(\S+?\.pdf)\">/o) 
		{	$url = "http://www.biochemsoctrans.org".$1;
		}
   	}
	return $url;
} 

sub ScienceDirect
{	my $url;
	my $jo = shift;
	my $pmid = shift;
	my $ye = shift;

	print "Dev Biol check: jo = $jo, ye = $ye\n";
	if ($jo eq "Dev Biol" && $ye < 1992)
	{	return;
	}

	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ / href=\"(\S+sdarticle\.pdf)\"/) 
		{	$url = $1;
		}
   	}
	return $url;
} 

sub DNA_Cell_Biol
{	
	my $pmid = shift;
	my $url;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ / href=\"((\S+)\/pdf\/(\S+))\"/)
		{	my $tmp = $1;
			$url = "http:\/\/www.liebertonline.com" . $tmp;
		}
   	}
	return $url;
}

sub SpringerLink
{	
	my $jo = shift;
	my $pmid = shift;
	my $ye = shift;

	if (($jo eq "Chromosoma" || ($jo eq "Cell Tissue Res")) && $ye < 1980)
	{
		open (NONDOWN, ">./output/other_non_downloadable.out");
		print NONDOWN "$pmid\n";
		print "Non-downloadable: Chromosoma pmid written to other_non_downloadable.out\n";
		print "____________________________________________________________________________________\n";
		close(NONDOWN);
		return;
	}

	my $url;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		#$auxcont = getwebpage($auxurl);
		#print "\n---\n$auxcont\n---\n";

		my @args = ("wget", "$auxurl", "-o", "log", "-O", "index");
		my $x = system(@args);
		if ($x != 0)
		{	print "wget did not work.\n";
			return;
		}
		

		open (SPRINGER_PAGE, "<./index");

		my $auxcont2 = "";
		while (<SPRINGER_PAGE>)
		{	$auxcont2 .= $_;
		}

		@args = ("rm", "-f", "index");
		#print "args = @args\n";
		system (@args) == 0 or die "system (@args) failed.\n";
		
		if ($auxcont2 =~ / href=\"(\S+\.pdf)\">Entire\s+document/)
		{	my $tmp = $1;
			$url = "http:\/\/www.springerlink.com" . $tmp;
		}
   	}
	return $url;
}

sub Sfx1
{	
	my $url;
	my $pmid = shift;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);

	if (CheckAtSfx($auxcont) == 0)
	{	return;
	}
	
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ /\"citation_abstract_html_url\" content=\"(http\S+)\"/)
		{	my $abstract_url = $1;
			$abstract_url =~ s/content\/abstract/reprint/;
			$url = $abstract_url . "\.pdf";
		}
   	}
	return $url;
}

sub Sfx2
{	
	my $url;
	my $pmid = shift;

	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);

	if (CheckAtSfx($auxcont) == 0)
	{	return;
	}
	
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ / href=\"(http\S+\.pdf)\">PDF(\s+)?\(\d+(.+)?\)/)
		{	$url = $1;
		}
   	}
	return $url;
}


	
sub Sfx3
{	my $url;
	my $pmid = shift;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);

	if (CheckAtSfx($auxcont) == 0)
	{	return;
	}
	
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		print "aux url = $auxurl\n";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ / href=\"(\S+?\.pdf)\">/o) 
		{	$url = $1;
		}
   	}
	return $url;
} 

sub NatureGeneric
{	my $url;
	my $pmid = shift;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);

	if (CheckAtSfx($auxcont) == 0)
	{	return;
	}
	
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
   	}
   	my $var2 = "";
    if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		$auxcont = getwebpage($auxurl);

		if ($auxcont =~ / href=\"(\S+?\/pdf\/\S+?\.pdf)\"/o) 
		{	$url = "http://www.nature.com".$1;
		}
		elsif ($auxcont =~ / src=\"(\/cgi-taf\/DynaPage\.taf\S+html)\"/)
		{
			my $tmp = $1; my $tmp2 = $2;
			$tmp =~ s/abs/full/;
			$tmp =~ s/\_l/\_fs/;
			$url = "http://www.nature.com" . $tmp . "&content_filetype=pdf";
		}
		elsif ($auxcont =~ / href=\"(\S+)\">Full Text/)
		{
			my $tmp1 = $1;
			$tmp1 =~ s/full/pdf/;
			$tmp1 =~ s/html/pdf/;
			$url = "http\:\/\/www.nature.com" . $tmp1;
		}
   	}
	return $url;
} 

sub Curr_Biol
{	
	my $jo = shift;
	my $pmid = shift;
	my $ye = shift;
	my $vo = shift;
	my $is = shift;
	my $pa = shift;
	my $basedir = shift;

	if ($pa =~ /^\d+$/)
	{	my $url = Sfx2($pmid);
		return $url;
	}

	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
	
	open (IN, "<$basedir/title/$pmid");
	my $title = "";
	while (<IN>)
	{	chomp;
		$title = $_;
	}
	close IN;

	# This crazy journal has all model organism names italicized in title!
	$title =~ s"([dD])rosophila"<i>$1rosophila<\/i>"; 
	$title =~ s"([Xx])enopus"<i>$1enopus<\/i>";
	print "Title = $title\n";

	$auxurl = "http://www.current-biology.com/content/vol$vo/issue$is/";
	$auxcont = getwebpage($auxurl);

	# Another crazy encoding of apostrophes!
	$auxcont =~ s/&#(\d+);/'/g;
	my $url;
	if ($auxcont =~ /($title(.*)<a href="(\S+\.pdf)">)/i)
	{	
		my $full = $1;
		$full =~ / href=\"(\S+pdf)\"/;
		$url = $1;
	}
	return $url;
}

sub CheckAtSfx
{	my $content = shift;
	if ($content =~ /No\s*Full\s*Text\s*Services\s*Available\s*from\s*the\s*Caltech\s*Library/i)
	{	return 0;
	} else
	{	return 1;
	}
}



#############################
### NEUROSCIENCE journals ###
#############################

sub Nat_Neurosci
{	my $url;
	my $pmid = shift;
	my $auxurl = "http://sfx.caltech.edu:8088/caltech?id=pmid:$pmid";
    my $auxcont = getwebpage($auxurl);
    my $var1 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_svc_id\' value=\'(\d+)\'/) 
	{	$var1 = $1;
    }
	print "v1 = $var1\n";
    my $var2 = "";
   	if ($auxcont =~ /name=\'tmp_ctx_obj_id\' value=\'(\d+)\'/) 
	{	$var2 = $1;
    }
	print "v2 = $var2\n";
    my $var3 = "";
    if ($auxcont =~ /name=\'service_id\' value=\'(\d+)\'/) 
	{	$var3 = $1;
    }
	print "v3 = $var3\n";
    my $var4 = "";
    if ($auxcont =~/name=\'request_id\' value=\'(\d+)\'/) 
	{	$var4 = $1;
    }
	print "v4 = $var4\n";
    if ( $var1 . $var2 . $var3 . $var4 ne "") 
	{	$auxurl = "http://sfx.caltech.edu:8088/caltech/cgi/core/sfxresolver.cgi?tmp_ctx_svc_id=$var1&tmp_ctx_obj_id=$var2&service_id=$var3&request_id=$var4";
		$auxcont = getwebpage($auxurl);
		if ($auxcont =~ /<a class=\"breadcrumblink\" href=\"(\S+?\.pdf)\">/o) 
		{	$url = "http://www.nature.com$1";
		} elsif ($auxcont =~ /<a href=\"(.+?\.html)\">Full Text<\/a>/o) 
		{   my $auxurl2 = "http://www.nature.com$1";
		    my $auxcont2 = getwebpage($auxurl2);
		    if ($auxcont2 =~ / href=\"(\S+?\.pdf)\">/o) 
			{	$url = "http://www.nature.com$1";
		    }
		}
    }
	return $url;
} 

sub Science_FullText
{	
	my $pmid = shift;
	my $vo = shift;
	my $is = shift;
	my $pa = shift;
	my $basedir = shift;

	my $html_page = getwebpage("http://www.sciencemag.org/cgi/content/full/$vo/$is/$pa");
	require HTML::TreeBuilder;
	my $tree = HTML::TreeBuilder->new->parse($html_page);
	require HTML::FormatText;
	my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 50);
	
	open (OUT, ">$basedir/body/$pmid") || die("04downloadPDF.pl::Science_FullText \'Cannot open output file $basedir/body/$pmid.\'\n");
	print OUT $formatter->format($tree);
	print "Full text directly written to $basedir/body/$pmid.\n";
	return;
}


### GENERAL SUBROUTINES

sub dumptext 
{   my $page = shift;
    my $file = shift;
    open (BOD, ">$file");
    print BOD $page;
    close (BOD);
}

sub getwebpage
{   my $u = shift;
	return if ($u eq "");
    my $page = "";
    
    my $ua = LWP::UserAgent->new(agent => 'Mozilla/5.0', timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
    print "Error while getting ", $response->request->url," -- ", $response->status_line, "\n" unless $response-> is_success;
    $page = $response->content;    #splits by line
    slp();
    return $page;
}

sub slp 
{   #my $rand = int(rand 5) + 5;
	my $rand = 2;
    print "Sleeping for $rand seconds...";
    sleep $rand;
    print "done.\n";
}

sub GetInputFile
{
	my $file = shift;
	open (IN, "<$file") || die ("In routine GetInputFile: Cannot find input file.\n");
	
	my $x = "\(";
	$x .= <IN>;
	chomp $x;
	while (<IN>)
	{	chomp;
		$x .= "|";
		$x .= $_;
	}
	$x .= "\)";
	close IN;
	return $x;
}

sub GetNdJournals
{
	my $pHash_Table = shift;
	my $infile = shift;
	open (IN, "<$infile") || die ("Cannot find input file non_downloadable_journals.in\n");
	while (<IN>)
	{	(my $jo, my $pmid, my $n) = /(.+) (\d+) (\d+)/;
		$$pHash_Table{$jo} = 1;
	}
	close IN;

	return;
}

sub NonDownloadableJournal
{
	my $jo = shift;
	my $pNon_Downloadable_Journals = shift;
	
	my $test = 0;
	foreach (keys %$pNon_Downloadable_Journals)
	{	$test = 1 if ($_ eq $jo);
	}
	print "We cannot yet download \"$jo\" papers automatically.\n" if ($test == 1);
	
	return $test;
}
