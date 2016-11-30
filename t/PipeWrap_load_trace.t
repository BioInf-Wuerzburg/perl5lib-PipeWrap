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
use Storable;


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


my $new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file);
#my $new_trace = PipeWrap->new(tasks => $tasks_trace);

is ($new->load_trace(), $new->_trace, "Test if trace file is created");

is (-e $trace_file, 1, "is trace file created?"); 

my $inputdata = retrieve($trace_file);

is_deeply ($new->_trace, $inputdata, "is inputdata in _trace?");

my $new2 = PipeWrap->new(tasks => $tasks, trace_file => $trace_file, _task_iter => 1);

$new2->load_trace();

is_deeply ($new2->_trace, $inputdata, "load tracefile");

is ($new2->{_task_iter}, 0, "_task_iter reset to 0");

$new->update_trace();

throws_ok { $new->load_trace("SwedishKitten") }  qr/Use force/, "must the force be with you!";




#test for logdie in loading needed!

unlink "test.trace";
is (-e $trace_file, undef, "is file still there? shouldn't!");

done_testing();
