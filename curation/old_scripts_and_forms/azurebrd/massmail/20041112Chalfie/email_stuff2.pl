#!/usr/bin/perl

# Get list of two_emails from postgres and email attachment PDF with Paul's
# text.  2003 02 25
#
# Edited to check that two_email doesn't have a space in the middle because
# it got an error :
# qmail-inject: fatal: unable to parse this line:
# To: e-mail: assafrn@tx.technion.ac.il
# requiring creating email_missing.pl to email to the emails after that error
# (see file ``emails'')  2003 10 28
#
# Changed subject to February 2004  and made body one line.  2004 02 17
#
# Changed subject to May 2004  and made body one line.  2004 05 04
#
# Changed subject to Aug 2004.  2004 08 09
#
# Use MSWORD instead of PDF to send Marty's email.  2004 11 12
#
# Sent this through mailer.  2004 11 15


use Jex;
use diagnostics;
use Pg;
use MIME::Lite;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



my %emails;
my $result = $conn->exec( "SELECT two_email FROM two_email WHERE two_email !~ '. .';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $emails{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# HERE UNCOMMENT TO SEND TO EVERYONE
# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mail_body("$_"); }

# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mimeAttacher("$_"); }

# Uncomment to print list of email addresses
# foreach $_ (sort keys %emails) { print "$_ : $emails{$_}\n"; }

# Sample mailing to myself or Paul
# &mail_body('azurebrd@minerva.caltech.edu');
# &mail_body('mc21@columbia.edu');
# &mimeAttacher('pws@caltech.edu');
# &mimeAttacher('mc21@columbia.edu');

# Sample mailing to ranjana
# &mimeAttacher('ranjana@its.caltech.edu');
# &mimeAttacher('kishoreranjana@hotmail.com');

# Mail to wormbase-announce
# &mimeAttacher('wormbase-announce@wormbase.org');


# &mail_body('azurebrd@minerva.caltech.edu');

sub mimeAttacher {
  my $email = shift;
  my $user = 'mc21@columbia.edu';
  my $subject = 'Identikit Project';
  my $attachment = 'IdentikitSupportLetter.doc';
#   my $attachment = 'WormBase_Newsletter_May2004.pdf';
#   my $attachment = 'WormBase_Newsletter_Oct2003.pdf';
  my $body = "Attached is a letter describing the Identikit Project";

  my $msg = MIME::Lite->new(
               From     =>"\"Martin Chalfie\" <$user>",
               To       =>"$email",
               Subject  =>"$subject",
               Type     =>'multipart/mixed',
               );
  $msg->attach(Type     =>'TEXT', 
               Data     =>"$body"
               );
  $msg->attach(Type     =>'Application/MSWORD', 
               Path     =>"$attachment",
               Filename =>"$attachment",
               Disposition => 'attachment'
               );
  $msg->send;

  print "SENT TO $email\n";
} # sub mimeAttacher

sub mail_body {
  my $email = shift;
  my $user = 'mc21@columbia.edu';
  my $subject = 'Identikit Project';
  my $body = "Dear Members of the C. elegans Community,

	One of the biggest problems facing the characterization of gene
expression patterns in C. elegans is the difficulty of identifying all the cells
expressing a given gene.  I would like to enlist your support for a
collaborative effort to create a C. elegans Identikit, a set of strains that
will allow the ready identification of gene expression patterns.  The Identikit
will be based on reconstituted GFP (recGFP), which was described in recent paper
from my lab (Zhang et al., Combinatorial marking of cells and organelles with
reconstituted fluorescent proteins Cell 119: 137-144, 2004).  recGFP is a two
component system that produces a fluorescent product only when both components
are made in the same cell.  The Identikit will consist of strains in which one
of the components is expressed from characterized promoters.  Constructs with
promoters to be tested are linked to the other recGFP component and transformed
into him animals.  The resulting transformant males can then be mated to
Identikit animals, and fluorescence should tell where the promoter is expressed.
We currently have three different color variants and can obtain either
cytoplasmic or nuclear labeling.  Thus, we should be able to label several
different cells in each strain.

	My lab is planning to construct the Identikit in collaboration with Don
Moerman (who is determining gene expression patterns for many promoters). I have
submitted a proposal for funding from NIH and Don is seeking funds from Genome
Canada.  Initially, we will demonstrate that multiple rec fluorescent proteins
can allow cells expression in the same animal and begin the construction of the
Identikit.  We will concentrate on generating strains that allow the
identification of the cells of the nervous system.  Ultimately, we want to have
strains that will identify all cells in the animal. A list of the promoters,
whose expression patterns we have or are confirming, is given below.  We will be
setting up a web site to describe our progress on the construction of the
Identikit (when this site is up, we will have a link through WormBase), and we
will make the strains freely available (probably through the C. elegans Stock
Center) as they are developed.  

	Don and I envision this effort as one involving the entire C. elegans
community.  I am writing not only to tell you about the project, but also to ask
for your support.  This support can take several forms.  First, I would
appreciate any letters of support, which I will include as supplemental
information for the grant application.  Please send such letters to me by email
(mc21\@columbia.edu).  Second, we would like to hear about any promoter fusions
that expressed intact GFP in a small numbers of cells, even if you do not know
the identity of the expressing cells.  For our purposes, the best strains are
those that express GFP early, strongly, and in very few and dispersed cell
types, but we are interested in hearing about any expressions that you feel
might be useful.  We would like to have the strains and will confirm or
determine the expression patterns.  We hope to obtain a large number of
promoters that can be used for the Identikit.  Below I've listed the promoters
we are examining at the moment and the cells they are expressed in.  In some
cases other promoters may have more restricted or stronger expression, so these
do not represent a final set.  Again, please email me your suggestions.  Third,
we would like to take advantage of your expertise. If you are particularly
knowledgeable about a part of the animal's anatomy and would like to be part of
this effort, please let us know.  For example, Scott Emmons has offered to help
us identify cells expressing recGFP in males.  Finally, we welcome any other
suggestions you care to make.

All the best,

Marty Chalfie


 ----------------------------------------------------------------
| GENE	  | CELLS	  | GENE    | CELLS                      |
 ----------------------------------------------------------------
| cat-2	  | ADE, PDE, CEP | mec-17* | ALM, PLM, AVM, PVM         |
| flp-1*  | AVK		  | odr-2b* | SMB, RME, ALN, PLN, RIG    |
| gcy-5*  | ASER	  | ser-2   | OLL, PVD                   |
| gcy-7*  | ASEL	  | sra-6   | PVQ, ASH                   |
| gcy-10* | AWB, AWC	  | tbh-1   | RIC                        |
| gcy-33  | BAG	  	  | tph-1*  | NSM, ADF, HSN, (AIM, RIH)  |
| glr-6*  | RIA		  | unc-4*  | SAB, DA, I5, VA, AVF, VC   |
| gpa-4*  | ASI		  | unc-47* | DD, VD, AVL, DVB, RME, RIS |
| gpa-8*  | URX, AQR, PQR | 	    |                            |
 ----------------------------------------------------------------

* indicates that the expression pattern has been verified; cells in parentheses
  fluoresced faintly.";

#   my $body = "We attach the February 2003 WormBase Newsletter. To help us improve 
# WormBase, we would appreciate your taking time to complete a short 
# on-line survey about WormBase at 
# http://www.wormbase.org/about/survey_2003.html.
# Thank you!
# 
# --The WormBase Consortium";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);	# email cecilia data
  print "SENT TO $email\n";
} # sub mail_body

