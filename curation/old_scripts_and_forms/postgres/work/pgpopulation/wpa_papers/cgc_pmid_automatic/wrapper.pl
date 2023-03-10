#!/usr/bin/perl -w

# Wrapper script to execute both scripts needed to update cgc-pmid correlation.
# Instructions : 
# Open a browser to http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi and
# search for ``elegans''.  Set the Display (button next to it) to MEDLINE,
# click DISPLAY again to reload.  Click the Save button (not the text
# button, since that only shows the first page of all the matches).  Save 
# as pubmed.medline.
# Run this script, which will use the data from the ref_ tables in pg to 
# get the cgc reference info, correlate with volume, pages, first author
# and create a table of one to one correspondences which are output to 
# an insertfile.pl, which drops the table, recreates it and its indices,
# and populates it with the newfound information.  2002 03 30
#
# check : pmid11821919    cgc5084
# check : pmid11779177    cgc5089 
# check : pmid11877381    cgc5123 (cgc5240)
# check : pmid12019227    cgc5274			2002 07 12
#
# added copyforced.pl which looks at ref_xrefpmidforced (list of cgc-pmid
# correlation made manually that the script will not pick up) and copies
# them to ref_xref;  2004 01 08


system(`/home/postgres/work/pgpopulation/cgc_pmid_automatic/pmcgchash.pl`);
system(`/home/postgres/work/pgpopulation/cgc_pmid_automatic/insertfile.pl`);
system(`/home/postgres/work/pgpopulation/cgc_pmid_automatic/copyforced.pl`);
