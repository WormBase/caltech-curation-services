#!/usr/bin/perl -w

# populate com_app_ tables from chris save file.  2015 11 02
#
# live run on tazendra.  2015 11 04

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;
my $infile = 'requests_to_fill_Allele-Phenotype_form_11-2-2015.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $header = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($papid, $pmid, $email, $date, $response, $form, $remark, @junk) = split/\t/, $line;
  if ($papid =~ m/\s/) { $papid =~ s/\s//g; }
  my ($month, $day, $year) = split/-/, $date;
  if ($day < 10) { $day = '0' . $day; }
  my $pgdate = $year . '-' . $month . '-' . $day;
  if ($email) {
    if ($email =~ m/\'/) { $email =~ s/\'/''/g; }
    push @pgcommands, qq(INSERT INTO com_app_emailsent_hst VALUES ('$papid', '$email', '$pgdate');); 
    push @pgcommands, qq(INSERT INTO com_app_emailsent VALUES ('$papid', '$email', '$pgdate');); }
  if ($response) {
    if ($response =~ m/\'/) { $response =~ s/\'/''/g; }
    push @pgcommands, qq(INSERT INTO com_app_emailresponse_hst VALUES ('$papid', '$response', '$pgdate'););
    push @pgcommands, qq(INSERT INTO com_app_emailresponse VALUES ('$papid', '$response', '$pgdate');); }
  if ($remark) {
    if ($remark =~ m/\'/) { $remark =~ s/\'/''/g; }
    push @pgcommands, qq(INSERT INTO com_app_remark_hst VALUES ('$papid', '$remark', '$pgdate'););
    push @pgcommands, qq(INSERT INTO com_app_remark VALUES ('$papid', '$remark', '$pgdate');); }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__

DELETE FROM com_app_emailsent_hst;
DELETE FROM com_app_emailsent;
DELETE FROM com_app_emailresponse_hst;
DELETE FROM com_app_emailresponse;
DELETE FROM com_app_remark_hst;
DELETE FROM com_app_remark;

WBPaper ID	PMID	email addresses e-mailed	Date emailed	email response	form response	Remark																		
00046396	25637722	darrell.killian@coloradocollege.edu	10-1-2015		Yes, 10-2-2015																			
00046395 	25637691	elke.neumann-haefelin@uniklinik-freiburg.de	10-1-2015																					
00046386	25644702	michael.koelle@yale.edu, bingjie.han@yale.edu	10-1-2015																					
00046381 	25627712	chamberlin.27@osu.edu, guptab@mcmaster.ca, sharan.coral@gmail.com	10-1-2015	Bhagwati replied that Devika would submit, 10-2-2015																				
00046365	25614239	ykohara@nig.ac.jp, hkagoshi@nig.ac.jp	10-1-2015																					
00046355 	25608529	hab28@cam.ac.uk	10-1-2015		Yes, 10-2-2015																			
00046353	25603799	hirotsu.takaaki.056@m.kyushu-u.ac.jp, beachriver14@gmail.com	10-1-2015																					
00046339 	25601206	ichiro.nakano@osumc.edu	10-1-2015			E-mail failed to send to kim.4758@osu.edu; Cecilia notified																		
00046306 	25567286	m.hilliard@uq.edu.au, brent.neumann@monash.edu	10-1-2015		Yes, 10-4-2015																			
00046304 	25569233	mitani.shohei@twmu.ac.jp	10-5-2015		Yes, 10-12-2015																			
00046301	25571900	James-Rand@ouhsc.edu, Eleanor-Mathews@omrf.ouhsc.edu	10-5-2015			E-mail failed to send to Eleanor-Mathews@omrf.ouhsc.edu; Cecilia notified																		
00046300 	25564762	ding.xue@colorado.edu, Hengwen.Yang@Colorado.EDU	10-5-2015																					
00046299	25564623	dhansen@ucalgary.ca, pratyush_9@hotmail.com	10-5-2015																					
00046298	25567989	kornfeld@wustl.edu	10-5-2015																					
00046292	25557666	  veena-prahlad@uiowa.edu, marcus-tatum@uiowa.edu	10-8-2015																					
00046900	26041936	barr@biology.rutgers.edu, jmaguire@biology.rutgers.edu	10-8-2015			E-mail failed to send to julimagu@eden.rutgers.edu; Cecilia notified; jmaguire@Biology.Rutgers.Edu seems to be the valid address																		
00046895	26052671	kangshen@stanford.edu, xingwei@stanford.edu	10-8-2015																					
00046893	26051896	yijin@ucsd.edu	10-8-2015																					
00046889 	26050091	hongzhang@sun5.ibp.ac.cn	10-8-2015																					
00046884	26032421	liebaue@uni-muenster.de, d_steg02@uni-muenster.de	10-8-2015																					
00046971	26124772	emmanuel.dassa@u-psud.fr, raynald.cossard@igmors.u-psud.fr	10-14-2015			Corr Auth Pred Good																		
00046962	26089518	smango@mcb.harvard.edu, hhsu@mcb.harvard.edu	10-14-2015			Corr Auth Pred Good																		
00046940	26073017	vincent.bertrand@univ-amu.fr, sabrina.murgan@univ-amu.fr	10-14-2015		Yes, 10-19-2015	Corr Auth Pred Good																		
00046902	25773600	haynesc@mskcc.org, nargunda@mskcc.org	10-14-2015			Corr Auth Pred Good																		
00046894	26052047	sebastian.leidel@mpi-muenster.mpg.de	10-14-2015			Corr Auth Pred Good																		
00046871	26030525	bjmeyer@berkeley.edu, emily@crane.net	10-14-2015			Corr Auth Pred Good																		
00046869	26028575	jean-louis.bessereau@univ-lyon1.fr, haijun.tu@hotmail.com, haijuntu@hnu.edu.cn	10-14-2015			Corr Auth Pred Good																		
00046852	25988162	anatbz@bgu.ac.il, annafru88@gmail.com	10-14-2015		Yes, 10-17-2015, submissions did not go to OA or history table, only to CG's e-mail; submissions entered manually, although will have to go through RNAi OA instead	Corr Auth Pred Good																		
00046827	25982673	xmwang@moon.ibp.ac.cn	10-14-2015		Yes, 10-19-2015	Corr Auth Pred Good																		
00046824	25984351	a.f.maia@ibmc.up.pt	10-14-2015		Yes, 10-19-2015	Not sure what happened; script pulls out first author (not the corresponding author) name and e-mail address, but the only e-mail address mentioned in the paper is that of the corresponding author, Rene Medema, who doesn't have a WBPerson ID																		
00046805	25968310	dustin.updike@mdibl.org, acampbell@mdibl.org	10-14-2015			Corr Auth Pred Good																		
00046786	25961505	alan.j.whitmarsh@manchester.ac.uk, gino.poulin@manchester.ac.uk, richard.monaghan@manchester.ac.uk	10-14-2015			Corr Auth Pred Good																		
00046779	25959238	mmaduro@citrus.ucr.edu, mmaduro@ucr.edu	10-14-2015	Morris Maduro responded (10-15-2015) to indicate that these are transgene phenotypes; CG responded		Morris Maduro is 1st & corresponding author, Scott Rifkin is last author																		
00046772	25956747	alain.nicolas@curie.fr	10-14-2015			Corr Auth Pred Good; missed 2nd corresponding author, not an issue																		
00046758	25544559	mhansen@sanfordburnham.org	10-14-2015			Corr Auth Pred Good; dwilkinson@salk.edu e-mail failed to send to this address; Cecilia notified																		
00046751	25938815	jeremy.nance@med.nyu.edu, diana.klompstra@med.nyu.edu	10-14-2015			Corr Auth Pred Good																		
00046716	25917219	garriga@berkeley.edu	10-14-2015			Corr Auth Pred Good																		
00046677	25891400	rougvie@umn.edu, mfukuyam@mol.f.u-tokyo.ac.jp	10-14-2015			Corr Auth Pred Good																		
00046675	25898168	mglotzer@uchicago.edu, angika@uchicago.edu	10-22-2015			Corr Auth Pred Good																		
00046672	25897023	victor.ambros@umassmed.edu, zhiji.ren@umassmed.edu	10-22-2015		Yes, 10-23-2015	Corr Auth Pred Good																		
00046670	25895060	fabrizio.dadda@ifom.eu	10-22-2015			Corr Auth Pred Good																		
00046659	25869670	jeremy.reiter@ucsf.edu	10-22-2015			Corr Auth Pred Good																		
00046658	25869139	voconno@soton.ac.uk, J.C.DILLON@soton.ac.uk, jcd@soton.ac.uk	10-22-2015	Heard back by e-mail 10-23-2015, CG made suggestions for phenotypes 10-23-2015		Corr Auth Pred Good																		
00046652	25866924	dumont@ijm.univ-paris-diderot.fr, gilliane.maton@ijm.fr	10-22-2015			Strange: the Corr Auth e-mail extracted is not mentioned in the paper. The (only) e-mail in the paper is for the Corr Auth and matches what is in WormBase, so the Corr Auth should have been recognized as WBPerson6561, but wasn't																		
00046645	25858456	gmichaux@univ-rennes1.fr, ghislain.gillard@gmail.com	10-22-2015			Corr Auth correctly identified, but the e-mail address returned is not the one mentioned in the paper																		
00046634	25850673	bill.weis@stanford.edu, choihj@snu.ac.kr	10-22-2015			Correctly predicted corresponding author, but incorrectly included Jeff Hardin (jdhardin@wisc.edu) as Corr Auth; predicted choihj@snu.ac.kr; choi 1st author																		
00046624	25819563	pmaddox@unc.edu, jc.labbe@umontreal.ca, abigail.gerhold@umontreal.ca	10-22-2015	Autoreply from Paul Maddox, 10-22-2015		Paul Maddox correctly identified as Corr Auth, but missed Jean-Claude Labbe																		
00046616	25843407	maricq@biology.utah.edu, horndli@biology.utah.edu	10-23-2015			Corr Auth Pred Good; hoernf@hotmail.com no good; Cecilia notified																		
00046615	25843030	guangshuoou@mail.tsinghua.edu.cn	10-23-2015		Yes, 10-24-2015	Corr Auth Pred Good																		
00046606	25827072	jrlu@ufl.edu	10-23-2015	Jianrong Lu forwarded to Siu Sylvia Lee and Veerle Rottiers, 10-23-2015		Corr Auth Pred Good																		
00046571	25753036	pintard.lionel@ijm.univ-paris-diderot.fr	10-23-2015			Corr Auth Pred Good; tavernier.nicolas@ijm.univ-paris-diderot.fr e-mail no good, Cecilia notified																		
00046563	25790851	xhuang@genetics.ac.cn, jb.wang@genetics.ac.cn	10-23-2015			Corr Auth Pred Good																		
