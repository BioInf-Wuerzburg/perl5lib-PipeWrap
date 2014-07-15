#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;

use FindBin qw($RealBin);
use lib "$RealBin/../lib/";

use Log::Log4perl qw(:easy :levels);
Log::Log4perl->init(\q(
        log4perl.rootLogger                               = DEBUG, Screen
        log4perl.appender.Screen                          = Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.stderr                   = 1
        log4perl.appender.Screen.layout                   = PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern = [%d{MM-dd HH:mm:ss}] [%C] %m%n
));


#--------------------------------------------------------------------------#
=head2 load module

=cut

BEGIN { use_ok('PipeWrap::Task'); }

my $Class = 'PipeWrap::Task';

#--------------------------------------------------------------------------#
=head2 sample data

=cut


# create data file names from name of this <file>.t
(my $Dat_file = $FindBin::RealScript) =~ s/t$/dat/; # data
(my $Dmp_file = $FindBin::RealScript) =~ s/t$/dmp/; # data structure dumped
(my $Tmp_file = $FindBin::RealScript) =~ s/t$/tmp/; # data structure dumped
(my $pre = $FindBin::RealScript) =~ s/.t$//; # data structure dumped

my ($Dat, %Dat, %Dmp);

if(-e $Dat_file){
	# slurp <file>.dat
	$Dat = do { local $/; local @ARGV = $Dat_file; <> }; # slurp data to string
	# %Dat = split("??", $Dat);
}

if(-e $Dmp_file){
    # eval <file>.dump
    %Dmp = do "$Dmp_file"; # read and eval the dumped structure
}


#-----------------------------------------------------------------------------##
=head1 ClassMethods

=cut


my $task_hash = {
    id => 'foo',
    cmd => [qw(perl -e 'print "task\tperl\n"')],
    parser => undef,
    };

my $o;
subtest 'new' => sub{
    $o = new_ok($Class, [%$task_hash]);
    cmp_deeply($o, bless($task_hash, $Class), 'new task object');
};

subtest 'generic' => sub{
    for my $acc (qw(id parser cmd)){
	can_ok($Class, $acc);
	is($o->$acc, $task_hash->{$acc}, $Class."->".$acc." get");
	is($o->$acc("wtf"), "wtf", $Class."->".$acc." set");
	is($o->$acc(undef,1), undef, $Class."->".$acc." unset");
	is($o->$acc($task_hash->{$acc}), $task_hash->{$acc}, $Class."->".$acc." reset");
    }
    
    is("$o", $o->id, 'overload ""');
};

subtest 'run' => sub{
    is($o->run(), "task\tperl\n", 'run with stdout to result');
};

done_testing();
