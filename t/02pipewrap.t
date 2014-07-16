#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;

use FindBin qw($RealBin);
use lib "$RealBin/../lib/";

use PipeWrap::Task;

use Log::Log4perl qw(:easy :levels);

my $level = @ARGV && $ARGV[0] =~ /^--?d/ ? "DEBUG" : "WARN" ;

Log::Log4perl->init(\(q(
        log4perl.rootLogger                               = ).$level.q(, Screen
        log4perl.appender.Screen                          = Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.stderr                   = 1
        log4perl.appender.Screen.layout                   = PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern = [%d{MM-dd HH:mm:ss}] [%C] %m%n
)));

my $L = Log::Log4perl->get_logger();


#--------------------------------------------------------------------------#
=head2 load module

=cut

BEGIN { use_ok('PipeWrap'); }

my $Class = 'PipeWrap';

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

my $dum = q(perl -e 'for (@ARGV){ $x = $x eq "\t" ? "\n" : "\t"; print $_,$x }');
my $opt = {'wtf' => 'TRUE', array => [7..9]};


my $ts =  [
    {
	id => 'foo',
	cmd => [q( perl -e 'print "task\tfoo"')],
    },
    {
	id => 'bin',
	cmd => [$dum, qw( bin %bin% )],
    },
    { 
	id => "rel",
	cmd => [$dum, qw( prev %[-1]% this %% other %{foo}% )] , 
    },
    {
	id => "opt",
	cmd => [$dum, qw( wtf %opt{wtf}% array %opt{array}%)],
	parser => "parse_csv"
    },
    {
	id => "res",
	cmd => [$dum, qw( wtf %res[-1]{wtf}% foo "%res{foo}%" )],
	parser => sub{ my $fh = shift; my @re = <$fh>; chomp(@re); return \@re}
    },
    ];


my $o;
subtest 'new' => sub{
    $o = new_ok($Class, [tasks => $ts, opt => $opt]);
    $L->debug(Dumper($o));
    cmp_deeply($o, $Dmp{pwo}, 'new task object');
};

subtest 'generics' => sub{
    # publics
    for my $acc (qw(tasks opt skip continue id trace_file)){
	can_ok($Class, $acc);
	my $cache;
	is(($cache = $o->$acc), $o->{$acc}, $Class."->".$acc." get");
	is($o->$acc("wtf"), "wtf", $Class."->".$acc." set");
	is($o->$acc(undef,1), undef, $Class."->".$acc." unset");
	is($o->$acc($cache), $o->{$acc}, $Class."->".$acc." reset");
    }

    # privates
    for my $acc (qw(trace task_iter task_index)){
	can_ok($Class, $acc);
	my $cache;
	is(($cache = $o->$acc), $o->{'_'.$acc}, $Class."->".$acc." get");
	is($o->$acc("wtf"), "wtf", $Class."->".$acc." set");
	is($o->$acc(undef,1), undef, $Class."->".$acc." unset");
	is($o->$acc($cache), $o->{'_'.$acc}, $Class."->".$acc." reset");
    }

    # trace
    for my $acc (qw(trace_task_results trace_update_time trace_init_time trace_task_done)){
	can_ok($Class, $acc);
	(my $accc = $acc) =~ s/trace_//;
	my $cache;
	is(($cache = $o->$acc), $o->trace->{$accc}, $Class."->".$acc." get");
	is($o->$acc("wtf"), "wtf", $Class."->".$acc." set");
	is($o->$acc(undef,1), undef, $Class."->".$acc." unset");
	is($o->$acc($cache), $o->trace->{$accc}, $Class."->".$acc." reset");
    }
    
    is("$o", $o->id, 'overload ""');
};

subtest 'run' => sub{
    # current_task
    can_ok($Class, 'current_task');
    # first
    is($o->current_task->id, $ts->[0]{id}, 'current_task get');
    is($o->run(), $ts->[0]{id}, 'run first task');
    is($o->trace_task_results->{$ts->[0]{id}}, "task\tfoo", 'stored stdout to result');

    # second
    is($o->current_task->id, $ts->[1]{id}, 'current_task get');
    is($o->run(), $ts->[1]{id}, 'run second task: %bin%');
    is($o->trace_task_results->{$ts->[1]{id}}, "bin\t$RealBin/\n", 'stored stdout to result');

    # third
    is($o->current_task->id, $ts->[2]{id}, 'current_task get');
    is($o->run(), $ts->[2]{id}, 'run third task: %-idx/idx%, %{ids}%');

    my $re = "prev	bin\nthis	rel\nother	foo\n";
    is($o->trace_task_results->{$ts->[2]{id}}, $re, 'stored stdout to result');

    # fourth
    is($o->current_task->id, $ts->[3]{id}, 'current_task get');
    is($o->run(), $ts->[3]{id}, 'run fourth task: %opt{..}%, parse_csv');
    cmp_deeply($o->trace_task_results->{$ts->[3]{id}}, { wtf => 'TRUE', array => 7, 8 => 9}, 'stored stdout via parse_csv');

    # fifth
    is($o->current_task->id, $ts->[4]{id}, 'current_task get');
    is($o->run(), $ts->[4]{id}, 'run fifth task: %res{..}%, custom parser');
    
    $re = ["wtf\tTRUE", "foo\ttask\tfoo"];

    cmp_deeply($o->trace_task_results->{$ts->[4]{id}}, $re, 'stored stdout via custom parser');
};

done_testing();
