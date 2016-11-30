#!/usr/bin/env perl
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PipeWrap.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Test::Class::Moose;
use Test::Exception;
use Log::Log4perl;

my $conf = q(
    log4perl.category                = INFO, Screen
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout  = Log::Log4perl::Layout::SimpleLayout
  );

# ... passed as a reference to init()
Log::Log4perl::init( \$conf );

BEGIN { use_ok('PipeWrap') };

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
is (%{$new->{_trace}->{task_results}}, %{$empty_hash}, "Test if %task_results is empty" );
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
is_deeply ($new->$damn_hashes, $new->{$damn_hashes}, "Test get ".$damn_hashes);
is_deeply ($new->$damn_hashes($kittens_alive), $kittens_alive, "Test set ".$damn_hashes);
}

my $kittens_stillalive = ["Hello", "Kitties"];

for my $damn_arrays (qw(skip)) {
can_ok($class, $damn_arrays);
is_deeply ($new->$damn_arrays, $new->{$damn_arrays}, "Test get ".$damn_arrays);
is_deeply ($new->$damn_arrays($kittens_stillalive), $kittens_stillalive, "Test set ".$damn_arrays);
}

for my $trace (qw(trace_task_results trace_init_time trace_update_time trace_task_done)) {
can_ok($class, $trace);
(my $tracewotrace = $trace) =~ s/trace_//;
is_deeply ($new->$trace, $new->_trace->{$tracewotrace}, "Test get ".$trace);
is ($new->$trace("KA"), "KA", "Test set ".$trace);
}

#---------TESTS4_set_tasks()---------#

can_ok ($class, "_set_tasks");

my @list = ({id => "Kittens"}, {id => "AsianKitten"});

my $new2 = PipeWrap->new();
$new2->_set_tasks(\@list);
isa_ok ($new2->{tasks}->[0], "PipeWrap::Task", "Test _set_tasks1");
isa_ok ($new2->{tasks}->[1], "PipeWrap::Task", "Test _set_tasks2");

#---------TESTS4index_tasks()---------#

can_ok($class, "index_tasks");

my $var1 = {id => "Kittens"};
my $var2 = {id => "BlackKitten"};
my $var3 = {id => "AsianKitten"};

$new = PipeWrap->new(tasks => [$var1, $var2, $var3]);
#$new->index_tasks();
is ($new->{_task_index}->{$var1->{id}}, 0, "Test if _task_index = 0");
is ($new->{_task_index}->{$var2->{id}}, 1, "Test if _task_index increases to 1 for the 2nd task");
is ($new->{_task_index}->{$var3->{id}}, 2, "Test if _task_index increases to 2 for the 3rd task");

#$new->index_tasks(); #Frank fragen: Wie testet man erfolgreich "die"?
#we tried expect to die, does not work with logdie but without:
throws_ok { PipeWrap->new(tasks => [$var1, $var1, $var3]) } qr/Non-unique task id/, "throw index_tasks: non-unique id";

#---------TESTS4current_task()---------#

can_ok ($class, "current_task");

my $tmp_file = "Test.trace";

$new = PipeWrap->new(tasks => [$var1, $var2, $var3], trace_file => $tmp_file);
is_deeply ($new->current_task()->id, $var1->{id}, "Test if current task is 0");

#---------TESTS4init_trace()---------#

can_ok ($class, "init_trace");

is ($new->init_trace(), $new->{_trace}, "Test init_trace");

is (time(), $new->{_trace}->{init_time}, "is time the true time");
#sleep(2);
is (time(), $new->{_trace}->{update_time}, "is time the true time2");

my $new_dies = PipeWrap->new(tasks => [$var1, $var2, $var3]);
throws_ok { $new_dies->init_trace() } qr/create/, "init_trace died: no file";

#---------TESTS4update_trace()---------#

can_ok ($class, "update_trace");
#sleep(2);
is ($new->update_trace(), $new->{_trace}, "Test update_trace");
throws_ok { $new_dies->update_trace() } qr/can't create/, "update_trace died: no file";

unlink $tmp_file;




done_testing();
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

