#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Class::Moose;
use Test::Exception;
use Log::Log4perl;
use Storable;
use List::Util qw(shuffle);

my $conf = q(
    log4perl.category                = INFO, Screen
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout  = Log::Log4perl::Layout::SimpleLayout
  );

# ... passed as a reference to init()

Log::Log4perl::init( \$conf );

BEGIN { use_ok('PipeWrap') };

my $class = "PipeWrap";
can_ok ($class, "load_trace");

my $tasks = [ {id => "AsianKitten", cmd => [ "berserk!" ]}, {id => "BlackKitten", cmd => ["smile"]}, {id => "SwedishKitten", cmd => ["pillage"]} ];

my $trace_file = "test.trace"; 
my $trace_file_broken = $trace_file."_broken";
my $new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file);

# my $new_trace = PipeWrap->new(tasks => $tasks_trace);

# Load or create a trace file, which contains the status of tasks

my $expected = $new->_trace;

is_deeply($new->load_trace(), $expected, "Test if trace file is created");

ok(-e $trace_file, "is trace file created?"); 
open(FH, "<", $trace_file) or die;
open(WH, ">", $trace_file_broken) or die;
binmode(FH);
my $filesize = -s $trace_file;
read(FH, my $content, $filesize);
my @output = shuffle split //, $content;

print WH join("", @output);
close(WH) or die;
close(FH) or die;


throws_ok {my $PW_obj = PipeWrap->new(tasks => $tasks, trace_file => $trace_file_broken, continue => 'AsianKitten')} qr/An unexpected error occured while trying to load file/, "is trace_file broken?";  

my $inputdata = retrieve($trace_file);

is_deeply ($new->_trace, $inputdata, "is inputdata in _trace?");

my $new2 = PipeWrap->new(tasks => $tasks, trace_file => $trace_file, _task_iter => 1);

$new2->load_trace();

is_deeply ($new2->_trace, $inputdata, "load tracefile");


# Run from new, no previous tasks

is ($new2->{_task_iter}, 0, "_task_iter reset to 0");

$new->update_trace();


# continue after spec task
# w/o force

throws_ok { $new->load_trace("SwedishKitten") }  qr/Use force/, "must the force be with you!";

#unlink $trace_file;

# w/ force
$new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file, force => "1");
is ($new->{_task_iter}, 0, "_task_iter is 0");

$new->update_trace();
$new->load_trace("SwedishKitten");

is ($new->{_task_iter}, 2, "_task_iter should now be 2");


# Unkown task

$new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file);
$new->update_trace();

throws_ok { $new->load_trace("Dogs") } qr/ unknown/, "Task unknown";


# Continue from last completed task

$new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file);

$new->update_trace(); # "complete" first task 

is ($new->{_task_iter}, 0, "'To be safe test1'");                        # Just to be sure
is_deeply ($new->trace_task_done, "AsianKitten", "'to be safe Test2'");  # Better safe than sorry

$new->load_trace();  
is ($new->{_task_iter}, 1, "increased task_iter by 1");


# Test: Completed tasks

$new->update_trace; #
$new->load_trace;   #  Finish tasks
$new->update_trace; #

throws_ok { $new->load_trace() } qr/Complete /, "Completed test";


# Test cannot continue

my $trace_file2 = "test2.trace";

my $trace = {task_results => {}, init_time => undef, update_time => undef, task_done => "GingerKitten"};

$new = PipeWrap->new(trace_file => $trace_file2, tasks => $tasks, _trace => $trace);


throws_ok { $new->load_trace() } qr/Cannot /, "Cannot continue";


# Test for logdie in loading needed!

unlink "test.trace", "test2.trace", "test.trace_broken";
is (-e $trace_file && $trace_file2, undef, "are files still there? shouldn't!");

done_testing();
