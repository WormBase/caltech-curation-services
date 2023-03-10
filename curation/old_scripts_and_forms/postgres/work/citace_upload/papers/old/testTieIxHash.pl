#!/usr/bin/perl 

# can't use Tie::IxHash because that stores in entry value.  If x gets
# entered, then x is made invalid, then y is entered, then x is made valid 
# again, it would show y instead of x, which came latest


use Tie::IxHash;

my %theHash;
tie %theHash, "Tie::IxHash";

$theHash{one} = 'invalid';
$theHash{two} = 'invalid';
$theHash{two} = 'valid';
$theHash{three} = 'invalid';
$theHash{three} = 'valid';
$theHash{three} = 'invalid';
$theHash{one} = 'valid';
$theHash{one} = 'invalid';
$theHash{one} = 'valid';

foreach my $identifier (sort keys %theHash) {
  if ($theHash{$identifier} eq 'valid') {
    print "VALID $identifier\n"; 
  }
}
