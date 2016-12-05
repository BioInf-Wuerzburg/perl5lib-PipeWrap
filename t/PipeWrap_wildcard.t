#!/usr/bin/env perl

########################################################################

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
can_ok ($class, "wildcard");

my $tasks = [ {id => "AsianKitten", cmd => [ "berserk!" ]}, {id => "BlackKitten", cmd => ["smile"]}, {id => "SwedishKitten", cmd => ["pillage"]} ];

my $trace_file = "test.trace"; 

my $new = PipeWrap->new(tasks => $tasks, trace_file => $trace_file);

my $tid = $new->current_task->id;

is ($new->wildcard($tid), $tid, "no pattern test");

my $p = '{LOL}';

throws_ok { $new->wildcard($tid, $p) } qr /Unknown/, "unknown task id test";


done_testing();
