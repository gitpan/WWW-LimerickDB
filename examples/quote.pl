#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib ../lib);
use WWW::LimerickDB;

@ARGV
    or die "Usage: perl $0 quote_number\n";

my $l = WWW::LimerickDB->new;

$l->get_limerick(shift)
    or die $l->error;

use Data::Dumper;
$Data::Dumper::Useqq=1;
print Dumper $l->limerick;

print $l . "\n";