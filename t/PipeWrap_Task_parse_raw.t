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

can_ok($class, "parse_raw");

my $data = \*DATA;
is ($new->parse_raw($data), "Kittens alive\n", "Test parse_raw");

done_testing();
__DATA__
Kittens alive
