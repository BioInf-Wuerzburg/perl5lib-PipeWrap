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

my $tasks = [ {id => "AsianKitten", cmd => ['perl -e print "done_AsianKitten"','%{AsianKitten}%' ]}, {id => "BlackKitten", cmd => ["smile"]}, {id => "SwedishKitten", cmd => ["pillage"]} ];

my $trace_file = "test_run.trace"; 

#my $new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file);

#my $task = $new->current_task;

#is_deeply ($new->resolve_task($task), $tasks->[0]->{"cmd"}, "test cmd");






unlink "test_run.trace";

done_testing();
