#!/usr/bin/env perl

# https://wiki.wormbase.org/index.php/Expression_Pattern#Populating_exp_transgene_based_on_exp_construct
# 2021 04 01
#
# 0 4 * * * /home/postgres/work/pgpopulation/exp_exprpattern/cronjobs/transfer_exp_cns_trp/wrapper.pl
#
# Daniela says 
# This script does the following:  runs overnight and looks for all constructs listed in Expression OA, 
# create a transgene object for such construct Populate the trp_fields as above copying data over from 
# the construct object.  Add the transgeneID just created in the transgene field of Expression OA for 
# which the construct was made Delete the construct from the construct field.
# Dockerized cronjob, no longer outputs logfile.  2023 03 15
#
# 0 4 * * * /usr/lib/scripts/pgpopulation/exp_exprpattern/cronjobs/transfer_exp_cns_trp/wrapper.pl



use strict;
use Jex;

my $date = &getSimpleDate();
print "DATE $date\n";

my $curdir = '/usr/lib/scripts/pgpopulation/exp_exprpattern/cronjobs/transfer_exp_cns_trp/';
`${curdir}1_copy_construct_to_transgene.pl`;
`${curdir}2_clean_exp_construct.pl`;

# my $curdir = '/home/postgres/work/pgpopulation/exp_exprpattern/cronjobs/transfer_exp_cns_trp/';
# `${curdir}1_copy_construct_to_transgene.pl > ${curdir}log_1_${date}`;
# `${curdir}2_clean_exp_construct.pl > ${curdir}log_2_${date}`;
