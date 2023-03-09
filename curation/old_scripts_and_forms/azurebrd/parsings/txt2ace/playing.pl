#!/usr/bin/perl
#
# Program to do the obvious


# for modifying strings into new value :
# for (@newhues = @oldhues)  { s/blue/red }

# for separetly getting rid of all surplus whitespaces
# for ($string) {
#   s/^\s+//;	# leading whitespaces
#   s/\s+$//;	# trailing whitespaces
#   s/\s+/ /g;	# internal whitespaces
# }



# playing with tr///*
# $str = "ferrous terrain teeth";
# $str =~ tr/ers/ghi/s;
# print "$str\n";

# print commas in right place
# $_ = 38410988841234;
# print "$_\n" while s/(\d)(\d\d\d)(?!\d)/$1,$2/;
# print "$_\n";

# for getting rid of all surplus whitespace
# $string = " 	   lalala  ho hoooo   ";
# $string = join(" ", split " ", $string);
# print "($string)\n";

# $str = "Hello cow 23, how are you on this 27th day ?";
# print "$str\n";
# $str =~ s/([0-9]+)/sprintf("%#x", $1)/ge;
# print "$str\n";

# $str2 = "This is version 2.0 to you.";
# print "$str2\n";
# %Names = qw(3.0 Isengard 2.0 Valhalla 1.0 Midgard);
# $str2 =~ s/version ([0-9.]+)/the $Names{$1} release/g;
# print "$str2\n";

# $str = "hello\ndummy\n";
# print "1 $str"."goodbye\n";
# $str =~ /(.*)/s;
# print "2 $1 2.2\n";
# $1 = "0";
# $str =~/(^.*)\n(^.*)/m;
# print "3 $1 $2 3.3\n";
# print "lala$/lala\n";
# $str2 = "hello\nhello goodbye\nhellocatara\n";
# print "$str2";
# $str2 =~ s/hell/heaven/g;
# print "$str2";
