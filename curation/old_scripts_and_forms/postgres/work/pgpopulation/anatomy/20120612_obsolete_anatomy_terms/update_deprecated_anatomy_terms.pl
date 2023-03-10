#!/usr/bin/perl -w

# update OA data for anatomy terms that have been deprecated with new terms.  2012 06 12
# live run on tazendra 2012 06 13

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;
my $infile = 'deprecated_terms.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($old, $new, $name) = split/\t/, $line;
  if ($name) { $name =~ s///; }
  $hash{$old}{new}  = $new;
  $hash{$old}{name} = $name;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


# OA tables and changes for them
my @tables = qw( app_anat_term exp_anatomy grg_pos_anatomy grg_neg_anatomy grg_not_anatomy pic_anat_term pro_anat_term );

my %data;
foreach my $table (@tables) {
  foreach my $old (sort keys %hash) {
    $result = $dbh->prepare( "SELECT * FROM $table WHERE $table ~ '$old'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      if ($row[0]) { $data{$table}{$row[0]}{$row[1]}{$old}++; }
} } }

my @pgcommands;
foreach my $table (sort keys %data) {
  foreach my $pgid (sort {$a<=>$b} keys %{ $data{$table} }) {
    foreach my $old_data (sort keys %{ $data{$table}{$pgid} }) {
      my $new_data = $old_data;  my $update = '';
      foreach my $old (sort keys %{ $data{$table}{$pgid}{$old_data} }) {
        $new_data =~ s/$old/$hash{$old}{new}/g;
        $update .= " change $old to $hash{$old}{new} $hash{$old}{name}";
#         print "$table\t$pgid\t$old_data\t$old\n";
      } # foreach my $old (sort keys %{ $data{$table}{$pgid}{$old_data} }
      push @pgcommands, qq(UPDATE $table SET $table = '$new_data' WHERE $table = '$old_data');
      push @pgcommands, qq(UPDATE ${table}_hst SET ${table}_hst = '$new_data' WHERE ${table}_hst = '$old_data');
# uncomment to show oa table + pgid changing
#       print "$table\t$pgid\t$old_data\t$new_data\t$update\n";
    } # foreach my $old_data (sort keys %{ $data{$table}{$pgid} })
  } # foreach my $pgid (sort keys %{ $data{$table} })
} # foreach my $table (sort keys %data)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO CHANGE DATA for OA tables
#   $dbh->do( $pgcommand );
} # foreach my $command (@pgcommands)


# Raymond's wbb anatomy_function stuff
# my %wbb;
# my @wbb = qw( wbb_involved wbb_notinvolved );
# foreach my $table (@wbb) {
#   foreach my $old (sort keys %hash) {
#     $result = $dbh->prepare( "SELECT * FROM $table WHERE $table ~ '$old'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) {
#         print qq($table\t$row[0]\t$row[2]\t$old to $hash{$old}{new} is $hash{$old}{name}\n);
# } } } }
  

# multiontology, so this doesn't work
# my $in = join"','", sort keys %hash;
# foreach my $table (@tables) {
#   $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IN ('$in')" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { print "@row\n"; }
#   }
# } # foreach my $table (@tables)

__END__

WBbt:0006980	WBbt:0004964	SPVL
WBbt:0006981	WBbt:0004963	SPVR
WBbt:0003943	WBbt:0006452	Cppppaa
WBbt:0003901	WBbt:0006481	Dpaaa
WBbt:0005655	WBbt:0004214	Z1.apppaaap
WBbt:0005639	WBbt:0004162	Z4.paaapapp
WBbt:0004722	WBbt:0008044	R1R_hyp
WBbt:0005390	WBbt:0005394	amphid neuron
WBbt:0005618	WBbt:0004137	Z4.apapppd
WBbt:0004691	WBbt:0004690	hyp3
WBbt:0004173	WBbt:0008059	R9L_hyp
WBbt:0004401	WBbt:0004392	hyp7
WBbt:0003726	WBbt:0004310	pm5VL
WBbt:0003725	WBbt:0004309	pm5VR
WBbt:0003835	WBbt:0006261	MSpppppa
WBbt:0007090	WBbt:0004963	SPVR
WBbt:0004680	WBbt:0004679	hyp6
WBbt:0004681	WBbt:0004679	hyp6
WBbt:0004682	WBbt:0004679	hyp6
WBbt:0004683	WBbt:0004679	hyp6
WBbt:0004684	WBbt:0004679	hyp6
WBbt:0005620	WBbt:0004138	Z4.apappav
WBbt:0003260	WBbt:0003626	Y.a nucleus
WBbt:0005099	WBbt:0005830	lumbar ganglion
WBbt:0003759	WBbt:0004323	pm3R
WBbt:0003875	WBbt:0006495	MSapappa
WBbt:0003840	WBbt:0006318	MSppappa
WBbt:0003686	WBbt:0004295	mc3DL
WBbt:0007080	WBbt:0004847	B_alpha.lv
WBbt:0005647	WBbt:0004140	Z4.appaapppa
WBbt:0005594	WBbt:0003754	M3 neuron
WBbt:0003700	WBbt:0004555	e1VR
WBbt:0003873	WBbt:0006469	MSappapp
WBbt:0003717	WBbt:0004305	pm7D
WBbt:0005640	WBbt:0004163	Z4.paaapapa
WBbt:0005613	WBbt:0004186	Z1.paappapp
WBbt:0004723	WBbt:0008043	R1L_hyp
WBbt:0003902	WBbt:0006297	Dapppp
WBbt:0005634	WBbt:0004158	Z4.paaappaa
WBbt:0003949	WBbt:0006378	Cppappa
WBbt:0003877	WBbt:0006306	MSapaaap
WBbt:0004686	WBbt:0004685	hyp5
WBbt:0005058	WBbt:0008321	Z1.ppaap male
WBbt:0007101	WBbt:0004829	B_gamma.arv
WBbt:0003697	WBbt:0004550	e2V
WBbt:0004719	WBbt:0008049	R4L_hyp
WBbt:0007094	WBbt:0004827	B_delta.r
WBbt:0003676	WBbt:0004335	pm1R
WBbt:0004289	WBbt:0006213	Capaaap
WBbt:0003975	WBbt:0006511	Cppaaaa
WBbt:0003947	WBbt:0006011	Cpppaaa
WBbt:0005610	WBbt:0004183	Z1.paapppp
WBbt:0007098	WBbt:0004831	B_gamma.alv
WBbt:0004177	WBbt:0008055	R7L_hyp
WBbt:0003948	WBbt:0006419	Cppappp
WBbt:0003640	WBbt:0004739	I6 neuron
WBbt:0003756	WBbt:0004320	pm4DL
WBbt:0003976	WBbt:0006337	Cappppv
WBbt:0002029	WBbt:0003704	g1P nucleus
WBbt:0003644	WBbt:0004324	pm3L
WBbt:0005621	WBbt:0004194	Z1.paappaapa
WBbt:0004185	WBbt:0008054	R6R_hyp
WBbt:0005649	WBbt:0004141	Z4.appaappap
WBbt:0003695	WBbt:0004548	e3D
WBbt:0003836	WBbt:0006659	MSppppap
WBbt:0003720	WBbt:0004306	pm6VR
WBbt:0005612	WBbt:0004148	Z4.appaaap
WBbt:0003259	WBbt:0003623	Y nucleus
WBbt:0004884	WBbt:0005798	anal sphincter muscle
WBbt:0003699	WBbt:0004556	e1VL
WBbt:0003922	WBbt:0006555	Cppppap
WBbt:0005323	WBbt:0005831	spicule neuron
WBbt:0003748	WBbt:0004315	pm4VR
WBbt:0003853	WBbt:0006022	MSpappppp
WBbt:0005611	WBbt:0004184	Z1.paapppa
WBbt:0003951	WBbt:0006148	Cppapaa
WBbt:0004695	WBbt:0004694	hyp1
WBbt:0004696	WBbt:0004694	hyp1
WBbt:0005317	WBbt:0006756	spermathecal-uterine junction
WBbt:0003876	WBbt:0006685	MSapapap
WBbt:0005643	WBbt:0004168	Z4.paaaaa
WBbt:0006080	WBbt:0004411	P9/10R
WBbt:0003944	WBbt:0006660	Cpppapp
WBbt:0004284	WBbt:0006538	Capappa
WBbt:0005630	WBbt:0004152	Z4.paaapppp
WBbt:0004394	WBbt:0008128	P7.p male
WBbt:0003839	WBbt:0006450	MSppappp
WBbt:0003913	WBbt:0006274	Dapppa
WBbt:0003842	WBbt:0006342	MSppaaap
WBbt:0003678	WBbt:0004336	pm1L
WBbt:0003900	WBbt:0006634	Dpaap
WBbt:0004172	WBbt:0005646	Z4.apaaaav
WBbt:0003671	WBbt:0004303	pm7VR
WBbt:0003841	WBbt:0005848	MSppapap
WBbt:0003880	WBbt:0006498	MSaapppap
WBbt:0003722	WBbt:0004307	pm6VL
WBbt:0003921	WBbt:0006113	Cpppppd
WBbt:0003727	WBbt:0004311	pm5R
WBbt:0004282	WBbt:0006182	Cappaaa
WBbt:0005616	WBbt:0004136	Z4.apapppv
WBbt:0003898	WBbt:0006366	Dpapp
WBbt:0003980	WBbt:0006406	Cappapp
WBbt:0003693	WBbt:0004546	e3VL
WBbt:0004286	WBbt:0005884	Capapaa
WBbt:0003685	WBbt:0004294	mc3DR
WBbt:0005652	WBbt:0004178	Z1.papaaav
WBbt:0003646	WBbt:0004325	pm3DR
WBbt:0003757	WBbt:0004321	pm3VR
WBbt:0004285	WBbt:0006559	Capapap
WBbt:0003750	WBbt:0004316	pm4VL
WBbt:0005626	WBbt:0004135	Z1.papppav
WBbt:0003834	WBbt:0006449	MSpppppp
WBbt:0003728	WBbt:0004312	pm5L
WBbt:0008035	WBbt:0006344	Dapaa
WBbt:0003680	WBbt:0004337	pm1DR
WBbt:0003915	WBbt:0006084	Dappaa
WBbt:0005615	WBbt:0004188	Z1.paappapap
WBbt:0003694	WBbt:0004544	e3VR
WBbt:0007103	WBbt:0004958	SPso1L
WBbt:0005627	WBbt:0004216	Z1.apppaaaa
WBbt:0003973	WBbt:0005926	Cppaapa
WBbt:0005617	WBbt:0004190	Z1.paappapaa
WBbt:0003982	WBbt:0005976	Cappaap
WBbt:0003715	WBbt:0004304	pm7VL
WBbt:0003896	WBbt:0005989	Dppap
WBbt:0002006	WBbt:0004536	exc_gl_L
WBbt:0003878	WBbt:0006397	MSaappppp
WBbt:0003978	WBbt:0006429	Capppap
WBbt:0004516	WBbt:0008048	R3R_hyp
WBbt:0003856	WBbt:0006354	MSpapppaa
WBbt:0003648	WBbt:0004326	pm3DL
WBbt:0006907	WBbt:0005815	diagonal muscle
WBbt:0003758	WBbt:0004322	pm3VL
WBbt:0003723	WBbt:0004308	pm6D
WBbt:0007682	WBbt:0003775	Z1.pppppap (5L)
WBbt:0003917	WBbt:0006381	Daapa
WBbt:0004395	WBbt:0008124	P6.p male
WBbt:0005619	WBbt:0004192	Z1.paappaapp
WBbt:0002027	WBbt:0003706	g1AL nucleus
WBbt:0004287	WBbt:0006040	Capaapp
WBbt:0005624	WBbt:0004134	Z1.pappppd
WBbt:0005802	WBbt:0004292	anal depressor muscle
WBbt:0003946	WBbt:0006187	Cpppaap
WBbt:0003916	WBbt:0006435	Daapp
WBbt:0004165	WBbt:0008056	R7R_hyp
WBbt:0003854	WBbt:0006742	MSpappppa
WBbt:0003897	WBbt:0006704	Dppaa
WBbt:0005609	WBbt:0004146	Z4.appaapaa
WBbt:0004542	WBbt:0005812	excretory cell
WBbt:0004515	WBbt:0008050	R4R_hyp
WBbt:0003719	WBbt:0004302	pm8
WBbt:0003952	WBbt:0006014	Cppaapp
WBbt:0003979	WBbt:0006682	Capppaa
WBbt:0003914	WBbt:0006320	Dappap
WBbt:0005608	WBbt:0004144	Z4.appaapapa
WBbt:0003642	WBbt:0004740	I5 neuron
WBbt:0003696	WBbt:0004552	e2DR
WBbt:0003882	WBbt:0006049	Dppppp
WBbt:0003690	WBbt:0004299	mc1V
WBbt:0003689	WBbt:0004298	mc2DL
WBbt:0003874	WBbt:0006235	MSapappp
WBbt:0005606	WBbt:0004203	Z1.appppa
WBbt:0003858	WBbt:0006637	MSpappaa
WBbt:0005628	WBbt:0004210	Z1.apppaapp
WBbt:0005650	WBbt:0004176	Z1.papaapv
WBbt:0005092	WBbt:0007650	Z1.ppaappa (5R)
WBbt:0007206	WBbt:0006770	P1
WBbt:0005623	WBbt:0004196	Z1.paappaaap
WBbt:0003730	WBbt:0004017	Cell
WBbt:0002007	WBbt:0004535	exc_gl_R
WBbt:0005435	WBbt:0005767	pharyngeal-intestinal valve
WBbt:0004393	WBbt:0008132	P8.p male
WBbt:0003729	WBbt:0004313	pm5DR
WBbt:0003636	WBbt:0004488	M1 neuron
WBbt:0007082	WBbt:0004836	B_alpha.rv
WBbt:0004283	WBbt:0006333	Capappp
WBbt:0007662	WBbt:0004047	Z1.ppapapp (5L)
WBbt:0003749	WBbt:0004465	M5 neuron
WBbt:0004720	WBbt:0008047	R3L_hyp
WBbt:0003655	WBbt:0004331	pm2DR
WBbt:0007653	WBbt:0005091	Z1.ppaappp (5L)
WBbt:0003752	WBbt:0004317	pm4R
WBbt:0003682	WBbt:0004338	pm1DL
WBbt:0003862	WBbt:0006523	MSapppaa
WBbt:0003879	WBbt:0006173	MSaappppa
WBbt:0005636	WBbt:0004206	Z1.apppapap
WBbt:0001714	WBbt:0003627	B nucleus
WBbt:0008157	WBbt:0006913	hermaphrodite alae seam cell
WBbt:0005625	WBbt:0004198	Z1.paappaaaa
WBbt:0003857	WBbt:0006426	MSpappap
WBbt:0003893	WBbt:0006265	Dppppa
WBbt:0003684	WBbt:0004293	mc3V
WBbt:0003974	WBbt:0006301	Cppaaap
WBbt:0003650	WBbt:0004327	pm2VR
WBbt:0005335	WBbt:0005364	anus
WBbt:0003981	WBbt:0006681	Cappapa
WBbt:0003899	WBbt:0006128	Dpapa
WBbt:0004397	WBbt:0008116	P4.p male
WBbt:0005228	WBbt:0005214	dorsal ganglion
WBbt:0004174	WBbt:0005648	Z4.apaaaad
WBbt:0003838	WBbt:0006667	MSpppapp
WBbt:0005631	WBbt:0004154	Z4.paaapppa
WBbt:0005629	WBbt:0004204	Z1.apppapp
WBbt:0005642	WBbt:0004166	Z4.paaaap
WBbt:0003855	WBbt:0005986	MSpapppap
WBbt:0003977	WBbt:0006537	Cappppd
WBbt:0005622	WBbt:0004133	Z1.pappppv
WBbt:0007097	WBbt:0004830	B_gamma.ald
WBbt:0006284	WBbt:0004412	P9/10L
WBbt:0003656	WBbt:0004332	pm2DL
WBbt:0004290	WBbt:0005954	Capaaaa
WBbt:0003753	WBbt:0004318	pm4L
WBbt:0003881	WBbt:0006195	MSaapppaa
WBbt:0007204	WBbt:0004489	M cell
WBbt:0004693	WBbt:0004692	hyp2
WBbt:0004717	WBbt:0008046	R2R_hyp
WBbt:0005512	WBbt:0003679	neuron
WBbt:0005516	WBbt:0003679	neuron
WBbt:0003776	WBbt:0007681	Z1.pppppaa (5L)
WBbt:0003745	WBbt:0004314	pm5DL
WBbt:0003691	WBbt:0004300	mc1DR
WBbt:0003861	WBbt:0005873	MSapppap
WBbt:0004721	WBbt:0008045	R2L_hyp
WBbt:0003652	WBbt:0004328	pm2VL
WBbt:0003698	WBbt:0004554	e2DL
WBbt:0003647	WBbt:0004742	I3 neuron
WBbt:0003687	WBbt:0004296	mc2V
WBbt:0007093	WBbt:0004828	B_delta.l
WBbt:0005436	WBbt:0005434	AB lineage
WBbt:0003860	WBbt:0006362	MSappppa
WBbt:0005614	WBbt:0004150	Z4.appaaaa
WBbt:0003859	WBbt:0006596	MSappppp
WBbt:0003920	WBbt:0005890	Cpppppv
WBbt:0005814	WBbt:0006909	longitudinal male muscle
WBbt:0004161	WBbt:0008058	R8R_hyp
WBbt:0007661	WBbt:0004049	Z1.ppapapa (5L)
WBbt:0005235	WBbt:0005237	touch receptor neuron
WBbt:0005239	WBbt:0005237	touch receptor neuron
WBbt:0003852	WBbt:0003851	AVF
WBbt:0006820	WBbt:0003851	AVF
WBbt:0003747	WBbt:0003664	MI neuron
WBbt:0004459	WBbt:0003664	MI neuron
WBbt:0005651	WBbt:0004142	Z4.appaappaa
WBbt:0003895	WBbt:0005858	Dpppaa
WBbt:0003950	WBbt:0005864	Cppapap
WBbt:0003657	WBbt:0004333	pm1VR
WBbt:0005783	WBbt:0004697	hmc
WBbt:0004379	WBbt:0004378	hyp10
WBbt:0004199	WBbt:0008053	R6L_hyp
WBbt:0005644	WBbt:0004170	Z4.apaaapv
WBbt:0003651	WBbt:0003638	MC neuron
WBbt:0005641	WBbt:0004164	Z4.paaapaa
WBbt:0004557	WBbt:0003701	e1D
WBbt:0004718	WBbt:0008051	R5L_hyp
WBbt:0004291	WBbt:0006138	ABprpppppaa
WBbt:0003918	WBbt:0005874	Daaap
WBbt:0003837	WBbt:0005990	MSppppaa
WBbt:0003688	WBbt:0004297	mc2DR
WBbt:0003919	WBbt:0006146	Daaaa
WBbt:0004363	WBbt:0005659	PHBR
WBbt:0005605	WBbt:0004208	Z1.apppapaa
WBbt:0004175	WBbt:0008057	R8L_hyp
WBbt:0004396	WBbt:0008120	P5.p male
WBbt:0005637	WBbt:0004202	Z1.appppp
WBbt:0004160	WBbt:0008060	R9R_hyp
WBbt:0004398	WBbt:0008111	P3.p male
WBbt:0005653	WBbt:0004143	Z4.appaapapp
WBbt:0003643	WBbt:0004741	I4 neuron
WBbt:0003653	WBbt:0004329	pm2R
WBbt:0003674	WBbt:0004334	pm1VL
WBbt:0003755	WBbt:0004319	pm4DR
WBbt:0003654	WBbt:0004330	pm2L
WBbt:0005398	WBbt:0005403	retrovesicular ganglion neuron
WBbt:0005404	WBbt:0005403	retrovesicular ganglion neuron
WBbt:0003692	WBbt:0004301	mc1DL
WBbt:0003746	WBbt:0003666	NSM
WBbt:0005211	WBbt:0005801	dorsal-rectal ganglion neuron
WBbt:0005387	WBbt:0005176	GLR
WBbt:0005782	WBbt:0005176	GLR
WBbt:0005654	WBbt:0004182	Z1.papaaad
WBbt:0003751	WBbt:0004467	M4 neuron
WBbt:0004288	WBbt:0006711	Capaapa
WBbt:0005635	WBbt:0004212	Z1.apppaapa
WBbt:0005632	WBbt:0004156	Z4.paaappap
WBbt:0005645	WBbt:0004139	Z4.appaapppp
WBbt:0004055	WBbt:0007651	Z1.ppaappp (5R)
WBbt:0008036	WBbt:0006535	Dapap
WBbt:0005764	WBbt:0005766	Anatomy
WBbt:0004514	WBbt:0008052	R5R_hyp
WBbt:0007104	WBbt:0004957	SPso1R
WBbt:0004688	WBbt:0004687	hyp4
WBbt:0004689	WBbt:0004687	hyp4
WBbt:0003894	WBbt:0006565	Dpppap
WBbt:0003945	WBbt:0006740	Cpppapa

