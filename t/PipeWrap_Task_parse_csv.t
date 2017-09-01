#!/usr/bin/env perl
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PipeWrap.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Test::Class::Moose;
BEGIN { use_ok('PipeWrap::Task') };
my $class = "PipeWrap::Task";

my $new = new_ok($class);

#---------TESTS4parse_csv()---------#

can_ok($class, "parse_csv");
my %csv_hash = ("Kittens" => "alive");
my $data = \*DATA;
is_deeply ($new->parse_csv($data), \%csv_hash, "Test parse_csv");

done_testing();

__DATA__
Kittens alive
