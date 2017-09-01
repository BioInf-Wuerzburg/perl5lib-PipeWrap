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

my $tasks = [ {id => "AsianKitten", cmd => [ "perl -e print 'Hello'" ]}, {id => "BlackKitten", cmd => ["perl -e print 'smile'"]}, {id => "SwedishKitten", cmd => ["perl -e print 'pillage'"]} ];

my $PO;

$PO = PipeWrap->new(tasks=>$tasks, continue => "");

ok(-e "PipeWrap_continue.t.trace", "file there?_standartname");

$PO->run();



my $PO2 = PipeWrap->new(tasks=>$tasks, continue => "");

$PO2->run();

is_deeply ($PO2->{_task_iter}, 2, "task_iter increased");



my $PO3 = PipeWrap->new(tasks=>$tasks, continue => "");

lives_ok { $PO3->run() }  "lives :D";

is_deeply ($PO3->{_task_iter}, 3, "increased again");

lives_ok { $PO3->run() } "complete";



unlink "PipeWrap_continue.t.trace";

done_testing();