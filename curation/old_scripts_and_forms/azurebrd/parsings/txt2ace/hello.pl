#!/usr/bin/perl
#
# Program to do the obvious

$str = "hello";
$num = 666;

print "$str" . $num . "goodbye\n";

open SPOOLER, "| date; ./sortendnote.pl; ls -l *.ace  ";
close SPOOLER;
