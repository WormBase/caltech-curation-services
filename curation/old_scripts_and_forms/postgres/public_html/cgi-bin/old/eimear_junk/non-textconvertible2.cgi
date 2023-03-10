#!/usr/bin/perl -w

use strict;
use CGI;
use CGI::Carp 'fatalsToBrowser';
use Fcntl;
use Pg;

my $query = new CGI;
my $version = "WS140";

my $conn = Pg::connectdb("dbname=demo4");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


&PrintHeader($query);
#&getNonTextConvertiblePapers;
#&PrintBottom($query);


sub getNonTextConvertiblePapers{

    my @paper_ids = ();
    #get all paper_ids of non-text convertible pdfs
    my $result = $conn->exec( "SELECT paper_id FROM wbp_electronic_status_index WHERE converts_well_to_text = 'f';" );
    while (my @row = $result->fetchrow) {
	my ($paper_id) = $row[0] =~ m/\/([^\/]*)$/;
	push @paper_ids, $paper_id;
    }
    for (@paper_ids){print "PAPER_IDS: $_\n"}
}	         	



sub PrintHeader { # begin PrintHeader
    my $query = shift;
    print $query->start_html(-title=>'Non Text Convertible PDFS', -author=>'Eimear Kenny',
			     -style=>{-src=>'http://www.wormbase.org/stylesheets/wormbase.css'}, 
			     -script=>'function c(p){location.href=p;return false};'
			     );
    print $query->h1(['Hello!']);
    #&PrintBanner($query);
    
} # end PrintHeader


sub PrintBottom{ # begin PrintBottom
    my $query = shift;

    print $query->br;
    print $query->hr;

    print $query->table({-border => '0', -cellpadding => '4',
			 -cellspacing => '1', -width => '100%'},
			$query->Tr([$query->td({-align=>'left', -style=>'small'},
					       $query->a({-href=>'mailto:webmaster@www.wormbase.org'}, 
							 ['webmaster@www.wormbase.org'])
					       ).
				    $query->td({-align=>'right',-style=>'small'},
					       $query->a({-href=>'http://www.wormbase.org/copyright.html'},
					       ['Copyright Statement'])
					       )
				    ]),
			$query->Tr([$query->td({-align=>'left', -style=>'small'},
					       $query->a({-href=>'http://www.wormbase.org/db/misc/feedback'}, 
							 ['Send comments or questions to WormBase'])
					       ).
				    $query->td({-align=>'right',-style=>'small'},
					       $query->a({-href=>'http://www.wormbase.org/privacy.html'},
							 ['Privacy Statement'])
					       )
				    ])
			);		
    return $query;
}   # end PrintBottom

sub PrintBanner{
    my $query = shift;
    print $query->table({-border => '0', -cellpadding => '4',
			 -cellspacing => '1', -width => '100%'},
			$query->Tr([$query->td({-bgcolor=>"#b4cbdb", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org'}, 
					       $query->font({-color=>"#FFFF99"}, 
                                               $query->b(
					       ['Home'])))
					       ).
				    $query->td({-bgcolor=>"#5870a3", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org/db/seq/gbrowse?source=wormbase'},
					       $query->font({-color=>"#FFFFFF"},
					       ['Genome']))
					       ).
				    $query->td({-bgcolor=>"#5870a3", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org/db/searches/blat'},
                                               $query->font({-color=>"#FFFFFF"},
					       ['Blast / Blat']))
					       ).
				    $query->td({-bgcolor=>"#5870a3", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org/db/searches/info_dump'},
                                               $query->font({-color=>"#FFFFFF"},
					       ['Batch Genes']))
					       ).
				    $query->td({-bgcolor=>"#5870a3", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org/db/searches/advanced/dumper'},
                                               $query->font({-color=>"#FFFFFF"},
					       ['Batch Sequences']))
					       ).
				    $query->td({-bgcolor=>"#5870a3", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org/db/searches/strains'},
                                               $query->font({-color=>"#FFFFFF"},
					       ['Markers']))
					       ).					       
				    $query->td({-bgcolor=>"#5870a3", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org/db/gene/gmap'},
                                               $query->font({-color=>"#FFFFFF"},
					       ['Genetic Maps']))
					       ).
				    $query->td({-bgcolor=>"#5870a3", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org/db/curate/base'},
                                               $query->font({-color=>"#FFFFFF"},
					       ['Submit']))
					       ).
				    $query->td({-bgcolor=>"#5870a3", -align=>'center', -nowrap},
					       $query->a({-href=>'http://www.wormbase.org/db/searches/search_index'}, 
					       $query->font({-color=>"#FFFFFF"}, 
					       $query->b(
					       ['More Searches'])))
					       )
				    ])
		       );

    print $query->table({-border => '0', -cellpadding => '0',
			 -cellspacing => '1', -width => '100%', -nowrap},
			$query->Tr({-valign=>'top', -class=>'white'},
				   [$query->td({-valign=>'middle', -align=>'center', width=>'50%'},
                                             $query->h3(
					       ['WormBase Release '.$version]
							)
					       ).
				   $query->td({-align=>'right'},
					      $query->a({-href=>'http://www.wormbase.org/'},
					      $query->img({-src=>'http://www.wormbase.org/images/image_new_colour.jpg',-alt=>'Wormbase banner image', -border=>'0'})))
				   ])
                        );									       

    print $query->p;
    return $query;
}

