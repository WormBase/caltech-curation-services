# replaces :
# 0 4 * * * /home/postgres/work/pgpopulation/textpresso/transgene/update_textpreso_cur_transgene.pl 
# 0 2 * * * /home/postgres/work/pgpopulation/transgene/textpresso_transgene/textpresso_transgene.pl 
# adds antibody textpresso updating for tfp_antibody table   2009 04 09


# 0 4 * * * /home/postgres/work/pgpopulation/textpresso/wrapper.sh

/home/postgres/work/pgpopulation/textpresso/transgene/update_textpresso_transgene.pl
# /home/postgres/work/pgpopulation/textpresso/antibody/update_textpresso_antibody.pl	# removed, daniela using cur_strdata  2018 07 25
# /home/postgres/work/pgpopulation/textpresso/rnai/update_textpresso_rnai.pl	# removed, gary using svm  2009 09 24
# /home/postgres/work/pgpopulation/afp_papers/find_passwd_@.pl 		# removed 2021 01 27, probably not needed anymore with Valerio having taken over AFP.  
# /home/postgres/public_html/cgi-bin/data/ccc_gocuration/get_newset.pl	# removed, not needed because of TPC  2017 02 09

