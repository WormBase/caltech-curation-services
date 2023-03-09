# this checks out PhenOnt from spica cvs, which perl can't do because of the @spica line (there must be a way to do it, I don't know how to)  2010 05 26
# export CVSROOT=':pserver:anonymous@spica.caltech.edu:/cvs'
# /usr/bin/cvs checkout PhenOnt
export CVSROOT=':pserver:anonymous@spica.caltech.edu:/PhenOnt'
/usr/bin/cvs co PhenOnt.obo

