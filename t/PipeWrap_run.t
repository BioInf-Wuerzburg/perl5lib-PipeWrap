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

my $trace_file = "test_run.trace"; 

my $new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file, skip => ["SwedishKitten"]);

$new->_task_iter(3);

is ($new->_task_iter, 3, "To be sure Task_itter is 3");
is (@{$new->tasks}, 3, "is also 3 -> done");

is ($new->run(), undef, "Test Pipeline completed - return undef test");

$new->_task_iter(4);
is ($new->_task_iter, 4, "To be sure Task_itter is 4");
throws_ok { $new->run() } qr/Trying to run/, "To much task_iter";


#-----

unlink "test_run.trace";

done_testing();
