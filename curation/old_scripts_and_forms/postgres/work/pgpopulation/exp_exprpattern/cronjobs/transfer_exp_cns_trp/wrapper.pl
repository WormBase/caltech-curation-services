#!/usr/bin/perl

# https://wiki.wormbase.org/index.php/Expression_Pattern#Populating_exp_transgene_based_on_exp_construct
# 2021 04 01
#
# 0 4 * * * /home/postgres/work/pgpopulation/exp_exprpattern/cronjobs/transfer_exp_cns_trp/wrapper.pl



use strict;
use Jex;

my $date = &getSimpleDate();
print "DATE $date\n";

my $curdir = '/home/postgres/work/pgpopulation/exp_exprpattern/cronjobs/transfer_exp_cns_trp/';

`${curdir}1_copy_construct_to_transgene.pl > ${curdir}log_1_${date}`;
`${curdir}2_clean_exp_construct.pl > ${curdir}log_2_${date}`;
