# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PipeWrap.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Test::Class::Moose;

BEGIN { use_ok('PipeWrap') };
#use_ok('Moose');
use_ok('PipeWrap::Task');

my $basename = "PipeWrap.t";
my $class = "PipeWrap";
my $test_value = 0; #just a testvalue

my $empty = []; #array default = empty
my $empty_hash = {}; #hash default = empty

my $new = new_ok($class);
###---------TESTS4PipeWrap---------#
#---------TESTS4new()---------#

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

#------------TESTS4new(accessors)---------#

for my $accessor (qw(continue trace_file force id)) {
can_ok($class, $accessor);
is ($new->$accessor, $new->{$accessor}, "Test get ".$accessor);
is ($new->$accessor("Kitten"), "Kitten", "Test set ".$accessor);
is ($new->$accessor(undef), undef, "Test undef ".$accessor);
}

my $kittens_alive = {Kittens => "alive"};

for my $damn_hashes (qw(_task_index opt _trace)) {
can_ok($class, $damn_hashes);
is ($new->$damn_hashes, $new->{$damn_hashes}, "Test get ".$damn_hashes);
is ($new->$damn_hashes($kittens_alive), $kittens_alive, "Test set ".$damn_hashes);
}

my $kittens_stillalive = ["Hello", "Kitties"];

for my $damn_arrays (qw(skip tasks)) {
can_ok($class, $damn_arrays);
is ($new->$damn_arrays, $new->{$damn_arrays}, "Test get ".$damn_arrays);
is ($new->$damn_arrays($kittens_stillalive), $kittens_stillalive, "Test set ".$damn_arrays);
}

for my $trace (qw(trace_task_results trace_init_time trace_update_time trace_task_done)) {
can_ok($class, $trace);
(my $tracewotrace = $trace) =~ s/trace_//;
is ($new->$trace, $new->_trace->{$tracewotrace}, "Test get ".$trace);
is ($new->$trace("KA"), "KA", "Test set ".$trace);
}


###---------Tests4PipeWrap::Task---------###

my $class_task = "PipeWrap::Task";

#my $new_task = new_ok($class_task);




done_testing();
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

