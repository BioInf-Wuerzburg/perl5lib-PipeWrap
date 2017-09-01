#!/usr/bin/env perl
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PipeWrap.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Log::Log4perl;

my $conf = q(
    log4perl.category                = INFO, Screen
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout  = Log::Log4perl::Layout::SimpleLayout
  );

# ... passed as a reference to init()
Log::Log4perl::init( \$conf );

use Test::More;
use Test::Class::Moose;
BEGIN { use_ok('PipeWrap::Task') };

my $basename = "foo";
my $class = "PipeWrap::Task";
my $test_value = 0; #just a testvalue

my $empty = []; #array default = empty
my $empty_hash = {}; #hash default = empty

my $hash = {id => 'foo', cmd => [qw(perl -e 'print "Task\tperl\n"')], parser => undef};

my $new = new_ok($class, [%$hash]);

###---------TESTS4PipeWrap::Task---------#
#---------TESTS4new()---------#

is ($new->{id}, $basename, "Test if id matches basename");
is ($new->{cmd}, $hash->{cmd}, "Test cmd");
is ($new->{parser}, undef, "Test parser");

for my $accessor (qw(id parser)) {
can_ok($class, $accessor);
is ($new->$accessor, $hash->{$accessor}, "Test get ".$accessor);
is ($new->$accessor("Kittens"), "Kittens", "Test set ".$accessor);
}
my $alive = [qw(perl -e 'print "no kittens died"')];
can_ok($class, "cmd");
is ($new->cmd, $hash->{cmd}, "Test get cmd");
is ($new->cmd($alive), $alive, "Test set cmd");

#---------TESTS4run()---------#

my $new2 = PipeWrap::Task->new($hash);
can_ok($class, "run");
is ($new2->run(), "Task\tperl\n", "Test run");

my $parsertest = PipeWrap::Task->new({id => 'foo', cmd => [qw(perl -e 'print "Task\tperl\n"')], parser => \&parser_test});

is($parsertest->run(), "Task\tperl\n", "Test custom parser");

done_testing();

sub parser_test {
    my ($fh) = @_;            
    return scalar do{local $/; <$fh>}
}
