# put all these stats into a single cronjob   2009 04 09

# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/wrapper.sh


# /home/postgres/work/get_stuff/for_erich/weekly_concise_summaries/get_recent.pl	# kimberly doesn't want this 2018 08 13
# /home/postgres/work/get_stuff/for_paul/curation_stats/go_curation_stats/get_recent.pl	# kimberly and paul don't want this 2015 08 17
/home/postgres/work/get_stuff/for_paul/curation_stats/allele_phenotype_stats/get_recent_app.pl
/home/postgres/work/get_stuff/for_paul/curation_stats/yh_curation_stats/get_recent.pl
# /home/postgres/work/get_stuff/for_paul/curation_stats/wbpaper_creation_stats/get_recent.pl	# kimberly and paul don't want this 2015 08 17
/home/postgres/work/get_stuff/for_paul/curation_stats/wbperson_creation_stats/get_recent.pl
/home/postgres/work/get_stuff/for_paul/curation_stats/wbperson_lineage_stats/get_recent.pl
/home/postgres/work/get_stuff/for_paul/curation_stats/wbpaper_author_person_stats/get_recent.pl
/home/postgres/work/get_stuff/for_paul/curation_stats/anatomy_function_stats/get_recent.pl
# /home/postgres/work/get_stuff/for_paul/curation_stats/ggi_stats/get_recent.pl
# /home/postgres/work/get_stuff/for_paul/curation_stats/cfp_curator_stats/get_recent.pl	# no longer doing much FP curation  2010 06 24

