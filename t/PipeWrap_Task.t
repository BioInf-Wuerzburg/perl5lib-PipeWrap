# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PipeWrap.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Test::Class::Moose;
use PipeWrap;
BEGIN { use_ok('PipeWrap::Task') };
use FindBin qw($RealBin);


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

#---------TESTS4parse_raw()---------#

can_ok($class, "parse_raw");

my $file =  "$RealBin/Task_parse_raw_file.txt";
open (my $fh, "<", $file) or die "Can't open ".$file.$!;


is ($new->parse_raw($fh), "Some kittens found shelter in this file. They didn't die!\n", "Test parse_raw");

#---------TESTS4parse_csv()---------#

can_ok($class, "parse_csv");
$file = "$RealBin/Task_parse_csv_file.txt";
open ($fh, "<", $file) or die "Can't open ".$file.$!;
my %csv_hash = ("Kittens" => "alive");
is (%{$new->parse_csv($fh)}, %csv_hash, "Test parse_csv");

done_testing();