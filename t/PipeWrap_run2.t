#!/usr/bin/env perl

########################################################################
use strict;
use warnings;

use Test::More;
use Test::Class::Moose;
use Test::Exception;
use Log::Log4perl;
use Storable;
use FindBin qw($RealBin);

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
can_ok ($class, "run");

my $tasks = [ {'id' => "AsianKitten", 'cmd' => ['perl -e \'print "done AsianKitten"\''],'parser' => undef }, {id => "BlackKitten", cmd => ['perl -e \'print "done_tasks"\'', "smile"]}, {id => "SwedishKitten", cmd => ['perl -e \'print "done_SwedisKitten"\'', "pillage"]} ];

my $trace_file = "test_run2.trace"; 

my $new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file, skip => ["SwedishKitten"]);

is ($new->_task_iter, 0, "sure be 0");

my $task = $new->current_task;

is_deeply ($new->run(), "$task", "Run_AsianKitten");

is ($new->trace_task_results->{$task}, "done AsianKitten", "results test1");

$task = $new->current_task;

is_deeply ($task->id, "BlackKitten", "Next Task loaded");

is_deeply ($new->run(), "$task", "Run_BlackKitten");

is ($new->trace_task_results->{$task}, "done_tasks", "results test2");

$task = $new->current_task;

is ($new->run(), "$task", "Task done cause skip");

is ($new->trace_task_results->{$task}, undef, "successfully skipped");

is ($new->run(), undef, "All tasks done");



unlink "test_run2.trace";

done_testing();
