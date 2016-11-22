# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PipeWrap.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Test::Class::Moose;

BEGIN { use_ok('PipeWrap') };
use_ok('Moose');

my $basename = "PipeWrap.t";
my $class = "PipeWrap";
my $test_value = 0; #just a testvalue

my $empty = []; #array default = empty
my $empty_hash = {}; #hash default = empty

my $new = new_ok($class);

is ($new->{id}, $basename, "Test if id matches basename");
is (@{$new->{tasks}}, @{$empty}, "Test if tasks is empty array");
is ($new->{continue}, undef, "Test if continue is initialized");
is (@{$new->{skip}}, @{$empty}, "Test if skip is empty array");
is ($new->{trace_file}, undef, "Test if trace_file is initialized");
is (%{$new->{opt}}, %{$empty_hash}, "Test if opt is empty hash");
is ($new->{force}, undef, "Test if force is initialized");

is ($new->{_task_iter}, $test_value, "Test if _task_iter is 0");
is (%{$new->{_task_index}}, %{$empty_hash}, "Test if _task_index is empty hash");
is (%{$new->{_trace}->{task_results}}, %{$empty_hash}, "" );
is ($new->{_trace}->{init_time}, undef, "God initialized time");
is ($new->{_trace}->{update_time}, undef, "God decided that time goes by");
is ($new->{_trace}->{task_done}, undef, "Achievement unlocked! Task done is initialized.");


done_testing();
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

